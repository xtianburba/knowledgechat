"""Knowledge base service"""
from sqlalchemy.orm import Session
from typing import List, Dict, Optional
from database import KnowledgeEntry, ImageEntry
from vector_store import get_vector_store
from scrapers import scrape_zendesk_articles, scrape_url_for_knowledge
from slugify import slugify
import json


class KnowledgeService:
    """Service for managing knowledge base"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def add_entry(
        self,
        title: str,
        content: str,
        url: Optional[str] = None,
        source: str = "manual",
        source_id: Optional[str] = None,
        created_by: Optional[int] = None,
        metadata: Optional[Dict] = None
    ) -> KnowledgeEntry:
        """Add a new knowledge entry"""
        # Create database entry
        entry = KnowledgeEntry(
            title=title,
            content=content,
            url=url,
            source=source,
            source_id=source_id or slugify(title),
            created_by=created_by,
            extra_metadata=json.dumps(metadata) if metadata else None
        )
        
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        
        # Add to vector store
        doc_id = f"{entry.id}_{slugify(title)}"
        vector_store = get_vector_store()
        vector_store.add_documents(
            documents=[content],
            ids=[doc_id],
            metadatas=[{
                "title": title,
                "source": source,
                "entry_id": entry.id,
                "url": url or ""
            }]
        )
        
        return entry
    
    def update_entry(
        self,
        entry_id: int,
        title: Optional[str] = None,
        content: Optional[str] = None,
        url: Optional[str] = None
    ) -> Optional[KnowledgeEntry]:
        """Update a knowledge entry"""
        entry = self.db.query(KnowledgeEntry).filter(KnowledgeEntry.id == entry_id).first()
        
        if not entry:
            return None
        
        if title:
            entry.title = title
        if content:
            entry.content = content
        if url is not None:
            entry.url = url
        
        self.db.commit()
        self.db.refresh(entry)
        
        # Update vector store
        doc_id = f"{entry.id}_{slugify(entry.title)}"
        vector_store = get_vector_store()
        vector_store.update_document(
            document=entry.content,
            doc_id=doc_id,
            metadata={
                "title": entry.title,
                "source": entry.source,
                "entry_id": entry.id,
                "url": entry.url or ""
            }
        )
        
        return entry
    
    def delete_entry(self, entry_id: int) -> bool:
        """Delete a knowledge entry"""
        entry = self.db.query(KnowledgeEntry).filter(KnowledgeEntry.id == entry_id).first()
        
        if not entry:
            return False
        
        # Delete from vector store
        doc_id = f"{entry.id}_{slugify(entry.title)}"
        vector_store = get_vector_store()
        vector_store.delete_document(doc_id)
        
        # Delete from database
        self.db.delete(entry)
        self.db.commit()
        
        return True
    
    def get_entry(self, entry_id: int) -> Optional[KnowledgeEntry]:
        """Get a knowledge entry by ID"""
        return self.db.query(KnowledgeEntry).filter(KnowledgeEntry.id == entry_id).first()
    
    def get_all_entries(self, skip: int = 0, limit: int = 100, source: Optional[str] = None) -> List[KnowledgeEntry]:
        """Get all knowledge entries, optionally filtered by source"""
        query = self.db.query(KnowledgeEntry)
        
        if source:
            query = query.filter(KnowledgeEntry.source == source)
        
        return query\
            .offset(skip)\
            .limit(limit)\
            .all()
    
    def get_sources(self) -> List[str]:
        """Get list of unique source types"""
        sources = self.db.query(KnowledgeEntry.source).distinct().all()
        return [source[0] for source in sources if source[0]]
    
    def search_entries(self, query: str, limit: int = 10) -> List[Dict]:
        """Search entries using vector store"""
        vector_store = get_vector_store()
        results = vector_store.search(query, n_results=limit)
        return results
    
    def sync_zendesk(self, created_by: Optional[int] = None) -> Dict:
        """Sync knowledge base with Zendesk"""
        try:
            articles = scrape_zendesk_articles()
            added = 0
            updated = 0
            errors = 0
            
            for article in articles:
                try:
                    # Check if entry exists
                    existing = self.db.query(KnowledgeEntry)\
                        .filter(KnowledgeEntry.source == "zendesk")\
                        .filter(KnowledgeEntry.source_id == article["source_id"])\
                        .first()
                    
                    if existing:
                        # Update existing
                        self.update_entry(
                            existing.id,
                            title=article["title"],
                            content=article["content"],
                            url=article["url"]
                        )
                        updated += 1
                    else:
                        # Create new
                        self.add_entry(
                            title=article["title"],
                            content=article["content"],
                            url=article["url"],
                            source="zendesk",
                            source_id=article["source_id"],
                            created_by=created_by,
                            metadata=json.loads(article["metadata"]) if article["metadata"] else None
                        )
                        added += 1
                except Exception as e:
                    print(f"Error processing article {article.get('source_id')}: {e}")
                    errors += 1
            
            return {
                "success": True,
                "added": added,
                "updated": updated,
                "errors": errors,
                "total": len(articles)
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def add_from_url(
        self,
        url: str,
        created_by: Optional[int] = None
    ) -> Optional[KnowledgeEntry]:
        """Add knowledge entry from URL"""
        try:
            article = scrape_url_for_knowledge(url)
            
            # Check if entry exists
            existing = self.db.query(KnowledgeEntry)\
                .filter(KnowledgeEntry.url == url)\
                .first()
            
            if existing:
                return self.update_entry(
                    existing.id,
                    title=article["title"],
                    content=article["content"]
                )
            else:
                return self.add_entry(
                    title=article["title"],
                    content=article["content"],
                    url=article["url"],
                    source="url",
                    source_id=article["source_id"],
                    created_by=created_by
                )
        except Exception as e:
            print(f"Error adding from URL {url}: {e}")
            return None


