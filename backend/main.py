"""Main FastAPI application"""
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from fastapi.responses import JSONResponse, FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, EmailStr
import os
from datetime import datetime, timedelta
import shutil
from pathlib import Path
import json
from sqlalchemy import func, desc, and_, Integer, cast
from collections import Counter

from config import settings
from database import init_db, get_db, User, KnowledgeEntry, ImageEntry, ChatInteraction, DocumentUsageStats
from auth import (
    get_current_user, 
    get_current_admin_user,
    get_current_supervisor_user,
    create_access_token,
    get_password_hash,
    verify_password
)
from services.knowledge_service import KnowledgeService
from rag_service import get_rag_service
from slugify import slugify
from scheduler import setup_zendesk_scheduler, get_scheduler_status

# Configure logging
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Initialize FastAPI app
app = FastAPI(
    title="OSAC Knowledge Bot API",
    description="API para sistema de base de conocimiento con IA",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    try:
        init_db()
        print("✓ Database initialized successfully")
    except Exception as e:
        print(f"⚠ Error initializing database: {e}")
        import traceback
        traceback.print_exc()
    
    # Setup Zendesk automatic sync if enabled
    if settings.zendesk_auto_sync and settings.zendesk_subdomain:
        setup_zendesk_scheduler(enabled=True, hour=settings.zendesk_sync_hour, minute=settings.zendesk_sync_minute)
        print(f"✓ Zendesk automatic sync enabled: Daily at {settings.zendesk_sync_hour:02d}:{settings.zendesk_sync_minute:02d} UTC")
    else:
        reason = []
        if not settings.zendesk_auto_sync:
            reason.append("ZENDESK_AUTO_SYNC is not enabled")
        if not settings.zendesk_subdomain:
            reason.append("ZENDESK_SUBDOMAIN is not configured")
        print(f"ℹ Zendesk automatic sync is disabled: {', '.join(reason)}")

# Pydantic models
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    is_admin: bool
    role: str = "user"
    
    class Config:
        from_attributes = True

class ChatMessage(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str
    sources: List[dict] = []
    context_count: int = 0

class KnowledgeEntryCreate(BaseModel):
    title: str
    content: str
    url: Optional[str] = None

class KnowledgeEntryUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    url: Optional[str] = None

class KnowledgeEntryResponse(BaseModel):
    id: int
    title: str
    content: str
    url: Optional[str]
    source: str
    created_at: datetime
    
    class Config:
        from_attributes = True

security = HTTPBearer()

# Auth endpoints
@app.post("/api/auth/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user - Only allowed if no users exist (to create first admin)"""
    try:
        # Check if any users exist
        user_count = db.query(User).count()
        
        # Only allow registration if no users exist (to create first admin)
        if user_count > 0:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Registration is disabled. Please contact an administrator to create an account."
            )
        
        # Check if user exists (shouldn't happen if user_count == 0, but just in case)
        existing_user = db.query(User).filter(
            (User.username == user_data.username) | (User.email == user_data.email)
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username or email already registered"
            )
        
        # This is the first user, make them admin
        hashed_password = get_password_hash(user_data.password)
        user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_password,
            is_admin=True,
            role="admin"  # First user is always admin
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        return user
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error registering user: {str(e)}"
        )

# Analytics endpoints (admin + supervisor)
@app.get("/api/analytics/overview")
async def get_analytics_overview(
    days: int = 30,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get analytics overview (supervisor/admin only)"""
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)
    
    # Total questions
    total_questions = db.query(ChatInteraction).filter(
        ChatInteraction.created_at >= start_date
    ).count()
    
    # Active users (users who asked at least one question)
    active_users = db.query(func.count(func.distinct(ChatInteraction.user_id))).filter(
        ChatInteraction.created_at >= start_date
    ).scalar()
    
    # Average questions per user
    avg_questions_per_user = total_questions / active_users if active_users > 0 else 0
    
    # Total users
    total_users = db.query(User).count()
    
    # Questions with no documents (no context found)
    questions_no_context = db.query(ChatInteraction).filter(
        and_(
            ChatInteraction.created_at >= start_date,
            ChatInteraction.context_count == 0
        )
    ).count()
    
    # Total knowledge entries
    total_documents = db.query(KnowledgeEntry).count()
    
    # Average response time
    avg_response_time = db.query(func.avg(ChatInteraction.response_time_ms)).filter(
        ChatInteraction.created_at >= start_date,
        ChatInteraction.response_time_ms.isnot(None)
    ).scalar() or 0
    
    return {
        "total_questions": total_questions,
        "active_users": active_users,
        "total_users": total_users,
        "avg_questions_per_user": round(avg_questions_per_user, 2),
        "questions_no_context": questions_no_context,
        "total_documents": total_documents,
        "avg_response_time_ms": round(float(avg_response_time), 2),
        "period_days": days
    }

@app.get("/api/analytics/questions-by-day")
async def get_questions_by_day(
    days: int = 7,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get questions count by day"""
    end_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    start_date = end_date - timedelta(days=days)
    
    # SQLite uses strftime for date extraction
    results = db.query(
        func.strftime('%Y-%m-%d', ChatInteraction.created_at).label('date'),
        func.count(ChatInteraction.id).label('count')
    ).filter(
        ChatInteraction.created_at >= start_date
    ).group_by(
        func.strftime('%Y-%m-%d', ChatInteraction.created_at)
    ).order_by(
        func.strftime('%Y-%m-%d', ChatInteraction.created_at)
    ).all()
    
    # Fill in missing days with 0
    date_dict = {str(row.date): row.count for row in results}
    filled_results = []
    current = start_date
    
    while current <= end_date:
        date_str = current.strftime('%Y-%m-%d')
        filled_results.append({
            "date": date_str,
            "count": date_dict.get(date_str, 0)
        })
        current += timedelta(days=1)
    
    return filled_results

@app.get("/api/analytics/top-questions")
async def get_top_questions(
    limit: int = 10,
    days: int = 30,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get most frequently asked questions"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get all questions in the period
    questions = db.query(ChatInteraction.question).filter(
        ChatInteraction.created_at >= start_date
    ).all()
    
    # Count occurrences (case-insensitive, normalized)
    question_counter = Counter()
    for (question,) in questions:
        # Normalize: lowercase and strip
        normalized = question.lower().strip()
        question_counter[normalized] += 1
    
    # Get top questions
    top_questions = question_counter.most_common(limit)
    
    return [
        {
            "question": question,
            "count": count
        }
        for question, count in top_questions
    ]

@app.get("/api/analytics/top-documents")
async def get_top_documents(
    limit: int = 10,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get most consulted documents"""
    stats = db.query(DocumentUsageStats).order_by(
        desc(DocumentUsageStats.times_used)
    ).limit(limit).all()
    
    result = []
    for stat in stats:
        entry = db.query(KnowledgeEntry).filter(
            KnowledgeEntry.id == stat.knowledge_entry_id
        ).first()
        
        if entry:
            result.append({
                "id": entry.id,
                "title": entry.title,
                "source": entry.source,
                "url": entry.url,
                "times_used": stat.times_used,
                "last_used_at": stat.last_used_at.isoformat() if stat.last_used_at else None
            })
    
    return result

@app.get("/api/analytics/top-users")
async def get_top_users(
    limit: int = 10,
    days: int = 30,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get most active users"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    results = db.query(
        ChatInteraction.user_id,
        func.count(ChatInteraction.id).label('question_count')
    ).filter(
        ChatInteraction.created_at >= start_date
    ).group_by(
        ChatInteraction.user_id
    ).order_by(
        desc('question_count')
    ).limit(limit).all()
    
    top_users = []
    for user_id, question_count in results:
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            last_activity = db.query(
                func.max(ChatInteraction.created_at)
            ).filter(
                ChatInteraction.user_id == user_id
            ).scalar()
            
            top_users.append({
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": getattr(user, 'role', 'user'),
                "question_count": question_count,
                "last_activity": last_activity.isoformat() if last_activity else None
            })
    
    return top_users

@app.get("/api/analytics/peak-hours")
async def get_peak_hours(
    days: int = 30,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get questions by hour of day (peak hours)"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # SQLite uses strftime('%H', datetime_column) to extract hour
    results = db.query(
        cast(func.strftime('%H', ChatInteraction.created_at), Integer).label('hour'),
        func.count(ChatInteraction.id).label('count')
    ).filter(
        ChatInteraction.created_at >= start_date
    ).group_by(
        func.strftime('%H', ChatInteraction.created_at)
    ).order_by(
        func.strftime('%H', ChatInteraction.created_at)
    ).all()
    
    # Fill in all 24 hours
    hour_dict = {int(row.hour): row.count for row in results}
    filled_results = []
    
    for hour in range(24):
        filled_results.append({
            "hour": hour,
            "count": hour_dict.get(hour, 0)
        })
    
    return filled_results

@app.get("/api/analytics/document-sources")
async def get_document_sources_stats(
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get statistics by document source"""
    results = db.query(
        KnowledgeEntry.source,
        func.count(KnowledgeEntry.id).label('count')
    ).group_by(
        KnowledgeEntry.source
    ).all()
    
    return [
        {
            "source": source,
            "count": count
        }
        for source, count in results
    ]

@app.get("/api/analytics/unused-documents")
async def get_unused_documents(
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get documents that have never been used"""
    used_ids = {stat.knowledge_entry_id for stat in db.query(DocumentUsageStats.knowledge_entry_id).all()}
    all_entries = db.query(KnowledgeEntry).all()
    
    unused = [
        {
            "id": entry.id,
            "title": entry.title,
            "source": entry.source,
            "created_at": entry.created_at.isoformat()
        }
        for entry in all_entries
        if entry.id not in used_ids
    ]
    
    return unused

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "message": "Backend is running"}

@app.post("/api/auth/login")
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """Login and get access token"""
    print(f"[LOGIN] Received login request for username: {credentials.username}")
    
    try:
        print(f"[LOGIN] Querying database for user: {credentials.username}")
        # Query user - use timeout protection
        user = None
        try:
            user = db.query(User).filter(User.username == credentials.username).first()
            print(f"[LOGIN] User query completed. User found: {user is not None}")
        except Exception as db_error:
            print(f"[LOGIN] Database error: {db_error}")
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al consultar la base de datos: {str(db_error)}"
            )
        
        if not user:
            print(f"[LOGIN] User not found: {credentials.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario no encontrado. Verifica que el nombre de usuario sea correcto. Recuerda que el nombre de usuario es sensible a mayúsculas y minúsculas."
            )
        
        print(f"[LOGIN] Verifying password for user: {credentials.username}")
        # Verify password
        password_valid = False
        try:
            password_valid = verify_password(credentials.password, user.hashed_password)
            print(f"[LOGIN] Password verification completed. Valid: {password_valid}")
        except Exception as pwd_error:
            print(f"[LOGIN] Password verification error: {pwd_error}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al verificar la contraseña: {str(pwd_error)}"
            )
        
        if not password_valid:
            print(f"[LOGIN] Invalid password for user: {credentials.username}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Contraseña incorrecta"
            )
        
        print(f"[LOGIN] Creating access token for user: {credentials.username}")
        # Create access token
        access_token = create_access_token(data={"sub": user.username})
        print(f"[LOGIN] Access token created successfully")
        
        # Update last login
        try:
            user.last_login = datetime.utcnow()
            db.commit()
            print(f"[LOGIN] Last login updated successfully")
        except Exception as commit_error:
            print(f"[LOGIN] Error updating last login: {commit_error}")
            db.rollback()
            # Don't fail the login if last_login update fails
        
        print(f"[LOGIN] Login successful for user: {credentials.username}")
        
        # Get role properly
        user_role = getattr(user, 'role', None)
        if not user_role or user_role == "":
            user_role = "admin" if user.is_admin else "user"
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_admin": user.is_admin or user_role == "admin",
                "role": user_role
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_msg = str(e)
        print(f"[LOGIN] Error in login: {error_msg}")
        print(f"[LOGIN] Traceback: {traceback.format_exc()}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al iniciar sesión: {error_msg}"
        )

@app.get("/api/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    # Ensure role is properly set
    user_role = getattr(current_user, 'role', None)
    if not user_role:
        # Fallback: set role based on is_admin if role is not set
        user_role = "admin" if current_user.is_admin else "user"
    
    return UserResponse(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        is_admin=current_user.is_admin or user_role == "admin",
        role=user_role
    )

# Chat endpoints
@app.post("/api/chat", response_model=ChatResponse)
async def chat(
    message: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Chat with the knowledge bot"""
    if not message.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty"
        )
    
    import time
    start_time = time.time()
    
    try:
        rag_service = get_rag_service()
        result = rag_service.chat(message.message)
        
        response_time_ms = int((time.time() - start_time) * 1000)
        
        # Extract document IDs from sources
        document_ids = []
        for source in result.get("sources", []):
            entry_id = source.get("entry_id")
            if entry_id:
                try:
                    # Ensure entry_id is an integer
                    entry_id_int = int(entry_id) if entry_id else None
                    if entry_id_int and entry_id_int not in document_ids:
                        document_ids.append(entry_id_int)
                except (ValueError, TypeError):
                    continue
        
        # Store interaction in database
        try:
            interaction = ChatInteraction(
                user_id=current_user.id,
                question=message.message,
                response_preview=result["response"][:200] if result["response"] else "",
                documents_used=json.dumps(document_ids) if document_ids else None,
                response_time_ms=response_time_ms,
                context_count=result.get("context_count", 0)
            )
            db.add(interaction)
            
            # Update document usage stats
            for doc_id in document_ids:
                stats = db.query(DocumentUsageStats).filter(
                    DocumentUsageStats.knowledge_entry_id == doc_id
                ).first()
                
                if stats:
                    stats.times_used += 1
                    stats.last_used_at = datetime.utcnow()
                else:
                    stats = DocumentUsageStats(
                        knowledge_entry_id=doc_id,
                        times_used=1,
                        last_used_at=datetime.utcnow()
                    )
                    db.add(stats)
            
            db.commit()
        except Exception as stats_error:
            # Don't fail the chat if stats recording fails
            print(f"Error recording chat statistics: {stats_error}")
            db.rollback()
        
        return ChatResponse(
            response=result["response"],
            sources=result.get("sources", []),
            context_count=result.get("context_count", 0)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing chat: {str(e)}"
        )

# Knowledge base endpoints
@app.get("/api/knowledge", response_model=List[KnowledgeEntryResponse])
async def get_knowledge_entries(
    skip: int = 0,
    limit: int = 100,
    source: Optional[str] = None,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get all knowledge entries, optionally filtered by source (supervisor/admin only)"""
    service = KnowledgeService(db)
    entries = service.get_all_entries(skip=skip, limit=limit, source=source)
    return entries

@app.get("/api/knowledge/sources")
async def get_knowledge_sources(
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Get list of available source types (supervisor/admin only)"""
    service = KnowledgeService(db)
    sources = service.get_sources()
    return {"sources": sources}

@app.get("/api/knowledge/{entry_id}", response_model=KnowledgeEntryResponse)
async def get_knowledge_entry(
    entry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific knowledge entry"""
    service = KnowledgeService(db)
    entry = service.get_entry(entry_id)
    
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Knowledge entry not found"
        )
    
    return entry

@app.post("/api/knowledge", response_model=KnowledgeEntryResponse)
async def create_knowledge_entry(
    entry_data: KnowledgeEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new knowledge entry"""
    service = KnowledgeService(db)
    entry = service.add_entry(
        title=entry_data.title,
        content=entry_data.content,
        url=entry_data.url,
        source="manual",
        created_by=current_user.id
    )
    return entry

@app.put("/api/knowledge/{entry_id}", response_model=KnowledgeEntryResponse)
async def update_knowledge_entry(
    entry_id: int,
    entry_data: KnowledgeEntryUpdate,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Update a knowledge entry"""
    service = KnowledgeService(db)
    entry = service.update_entry(
        entry_id=entry_id,
        title=entry_data.title,
        content=entry_data.content,
        url=entry_data.url
    )
    
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Knowledge entry not found"
        )
    
    return entry

@app.delete("/api/knowledge/{entry_id}")
async def delete_knowledge_entry(
    entry_id: int,
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Delete a knowledge entry (supervisor/admin only)"""
    service = KnowledgeService(db)
    success = service.delete_entry(entry_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Knowledge entry not found"
        )
    
    return {"success": True}

# Zendesk sync endpoint
@app.post("/api/knowledge/sync/zendesk")
async def sync_zendesk(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Sync knowledge base with Zendesk (admin only)"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can sync with Zendesk"
        )
    
    service = KnowledgeService(db)
    result = service.sync_zendesk(created_by=current_user.id)
    
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result.get("error", "Error syncing with Zendesk")
        )
    
    return result

# Zendesk scheduler status and configuration (admin only)
@app.get("/api/knowledge/sync/zendesk/status")
async def get_zendesk_sync_status(
    current_user: User = Depends(get_current_admin_user)
):
    """Get Zendesk automatic sync status"""
    status = get_scheduler_status()
    status.update({
        "zendesk_configured": bool(settings.zendesk_subdomain),
        "auto_sync_enabled": settings.zendesk_auto_sync,  # Use settings instead of os.getenv
        "sync_hour": settings.zendesk_sync_hour,
        "sync_minute": settings.zendesk_sync_minute
    })
    return status

# URL scraping endpoint
@app.post("/api/knowledge/from-url", response_model=KnowledgeEntryResponse)
async def add_knowledge_from_url(
    url: str = Form(...),
    current_user: User = Depends(get_current_supervisor_user),
    db: Session = Depends(get_db)
):
    """Add knowledge entry from URL"""
    # Validate URL format
    try:
        from urllib.parse import urlparse
        parsed = urlparse(url)
        if not parsed.scheme or not parsed.netloc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="URL inválida. Debe tener formato: http://ejemplo.com o https://ejemplo.com"
            )
    except Exception as e:
        if isinstance(e, HTTPException):
            raise
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="URL inválida. Verifica el formato de la URL."
        )
    
    try:
        service = KnowledgeService(db)
        entry = service.add_from_url(url, created_by=current_user.id)
        
        if not entry:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Error al procesar la URL. Verifica que la URL sea accesible y contenga contenido."
            )
        
        return entry
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al añadir contenido desde URL: {str(e)}"
        )

# Image upload endpoint
@app.post("/api/knowledge/{entry_id}/images")
async def upload_image(
    entry_id: int,
    file: UploadFile = File(...),
    description: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload an image for a knowledge entry"""
    # Verify entry exists
    entry = db.query(KnowledgeEntry).filter(KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Knowledge entry not found"
        )
    
    # Validate file type
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Check file size
    file_content = await file.read()
    if len(file_content) > settings.max_upload_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large"
        )
    
    # Save file
    upload_dir = Path(settings.upload_dir) / "images"
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    file_ext = Path(file.filename).suffix
    safe_filename = f"{entry_id}_{slugify(Path(file.filename).stem)}{file_ext}"
    file_path = upload_dir / safe_filename
    
    with open(file_path, "wb") as f:
        f.write(file_content)
    
    # Create database entry
    image_entry = ImageEntry(
        filename=file.filename,
        filepath=str(file_path.relative_to(".")),
        knowledge_entry_id=entry_id,
        uploaded_by=current_user.id,
        description=description
    )
    
    db.add(image_entry)
    db.commit()
    db.refresh(image_entry)
    
    return {
        "id": image_entry.id,
        "filename": image_entry.filename,
        "url": f"/api/images/{image_entry.id}",
        "description": image_entry.description
    }

# Image retrieval endpoint
@app.get("/api/images/{image_id}")
async def get_image(
    image_id: int,
    db: Session = Depends(get_db)
):
    """Get an image by ID"""
    image_entry = db.query(ImageEntry).filter(ImageEntry.id == image_id).first()
    
    if not image_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image not found"
        )
    
    file_path = Path(image_entry.filepath)
    if not file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image file not found"
        )
    
    return FileResponse(file_path)

# User management endpoints (admin only)
@app.get("/api/users", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get all users (admin only)"""
    users = db.query(User)\
        .offset(skip)\
        .limit(limit)\
        .all()
    return users

@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Get a specific user (admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user

@app.post("/api/users", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new user (admin only)"""
    # Check if user exists
    existing_user = db.query(User).filter(
        (User.username == user_data.username) | (User.email == user_data.email)
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create user with default role
    hashed_password = get_password_hash(user_data.password)
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password,
        is_admin=False,
        role="user"  # Default role
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None
    is_admin: Optional[bool] = None
    role: Optional[str] = None

@app.put("/api/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Update a user (admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Prevent updating yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot update your own user from here. Use profile settings instead."
        )
    
    # Check if new username/email already exists
    if user_data.username and user_data.username != user.username:
        existing = db.query(User).filter(User.username == user_data.username).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        user.username = user_data.username
    
    if user_data.email and user_data.email != user.email:
        existing = db.query(User).filter(User.email == user_data.email).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already taken"
            )
        user.email = user_data.email
    
    if user_data.password:
        user.hashed_password = get_password_hash(user_data.password)
    
    if user_data.role:
        # Validate role
        valid_roles = ["admin", "supervisor", "user"]
        if user_data.role not in valid_roles:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}"
            )
        user.role = user_data.role
        # Also update is_admin for backward compatibility
        user.is_admin = (user_data.role == "admin")
    elif user_data.is_admin is not None:
        # Backward compatibility: if role not provided but is_admin is, update both
        user.is_admin = user_data.is_admin
        if user_data.is_admin:
            user.role = "admin"
    
    db.commit()
    db.refresh(user)
    
    return user

@app.delete("/api/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """Delete a user (admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Prevent deleting yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own user"
        )
    
    db.delete(user)
    db.commit()
    
    return {"success": True, "message": "User deleted successfully"}

# Health check

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


