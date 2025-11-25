"""Database setup and models"""
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

# SQLite database for users
DATABASE_URL = "sqlite:///./knowledge_bot.db"

engine = create_engine(
    DATABASE_URL, 
    connect_args={
        "check_same_thread": False,
        "timeout": 10.0  # 10 second timeout for database operations
    },
    pool_pre_ping=True,  # Verify connections before using them
    pool_recycle=3600  # Recycle connections after 1 hour
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class User(Base):
    """User model for authentication"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_admin = Column(Boolean, default=False)  # Kept for backward compatibility
    role = Column(String, default="user")  # Options: "admin", "supervisor", "user"
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    @property
    def is_admin_role(self):
        """Check if user has admin role"""
        return self.role == "admin" or self.is_admin  # Backward compatibility


class KnowledgeEntry(Base):
    """Knowledge base entry model"""
    __tablename__ = "knowledge_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    content = Column(Text, nullable=False)
    url = Column(String, nullable=True)
    source = Column(String, default="manual")  # manual, zendesk, url
    source_id = Column(String, nullable=True)  # ID from Zendesk or external source
    created_by = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    extra_metadata = Column(Text, nullable=True)  # JSON string for additional metadata (renamed from 'metadata' which is reserved in SQLAlchemy)


class ImageEntry(Base):
    """Image entry model"""
    __tablename__ = "image_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    filepath = Column(String, nullable=False)
    knowledge_entry_id = Column(Integer, nullable=True)  # Associated with knowledge entry
    uploaded_by = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    description = Column(Text, nullable=True)


class ChatInteraction(Base):
    """Chat interaction model for analytics"""
    __tablename__ = "chat_interactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    question = Column(Text, nullable=False)
    response_preview = Column(Text, nullable=True)  # First 200 chars of response
    documents_used = Column(Text, nullable=True)  # JSON array of document IDs
    response_time_ms = Column(Integer, nullable=True)  # Response time in milliseconds
    context_count = Column(Integer, default=0)  # Number of documents used in context
    created_at = Column(DateTime, default=datetime.utcnow, index=True)


class DocumentUsageStats(Base):
    """Document usage statistics"""
    __tablename__ = "document_usage_stats"
    
    id = Column(Integer, primary_key=True, index=True)
    knowledge_entry_id = Column(Integer, nullable=False, index=True, unique=True)
    times_used = Column(Integer, default=0)
    last_used_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)
    
    # Create upload directory if it doesn't exist
    upload_dir = "./uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    # Create images directory
    images_dir = os.path.join(upload_dir, "images")
    os.makedirs(images_dir, exist_ok=True)


def get_db():
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


