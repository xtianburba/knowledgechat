"""Vector store for RAG using ChromaDB"""
# Patch SQLite antes de importar chromadb
import sqlite_patch
import chromadb
from typing import List, Dict, Optional
import json
from config import settings
import os

# Check ChromaDB version to use appropriate API
try:
    import chromadb.config
    from chromadb.config import Settings as ChromaSettings
    CHROMADB_NEW_API = True
except (ImportError, AttributeError):
    CHROMADB_NEW_API = False


class VectorStore:
    """Vector store wrapper for ChromaDB"""
    
    def __init__(self):
        """Initialize ChromaDB client (compatible with both 0.3.x and 0.4.x)"""
        os.makedirs(settings.chroma_db_path, exist_ok=True)
        
        # Try new API first (ChromaDB 0.4+)
        try:
            self.client = chromadb.PersistentClient(
                path=settings.chroma_db_path,
                settings=ChromaSettings(
                    anonymized_telemetry=False,
                    allow_reset=True
                )
            )
            self.collection = self.client.get_or_create_collection(
                name="knowledge_base",
                metadata={"hnsw:space": "cosine"}
            )
        except (AttributeError, TypeError, Exception) as e:
            # Fallback to old API (ChromaDB 0.3.x)
            # Try to disable telemetry first
            try:
                os.environ["ANONYMIZED_TELEMETRY"] = "False"
            except:
                pass
            
            # For ChromaDB 0.3.x, try without settings first
            try:
                self.client = chromadb.Client()
                # Set persist directory after creation
                import chromadb.config
                if hasattr(chromadb.config, 'Settings'):
                    settings_obj = chromadb.config.Settings(
                        chroma_db_impl="duckdb+parquet",
                        persist_directory=settings.chroma_db_path,
                        anonymized_telemetry=False
                    )
                    self.client = chromadb.Client(settings=settings_obj)
                else:
                    self.client = chromadb.Client()
            except Exception as e2:
                # Last resort: try with minimal settings
                try:
                    from chromadb.config import Settings as ChromaSettingsOld
                    settings_obj = ChromaSettingsOld(
                        chroma_db_impl="duckdb+parquet",
                        persist_directory=settings.chroma_db_path,
                        anonymized_telemetry=False
                    )
                    self.client = chromadb.Client(settings=settings_obj)
                except:
                    # If all else fails, use default client
                    self.client = chromadb.Client()
            
            self.collection = self.client.get_or_create_collection(
                name="knowledge_base"
            )
    
    def add_documents(
        self, 
        documents: List[str], 
        ids: List[str], 
        metadatas: Optional[List[Dict]] = None
    ):
        """Add documents to the vector store"""
        if metadatas is None:
            metadatas = [{}] * len(documents)
        
        self.collection.add(
            documents=documents,
            ids=ids,
            metadatas=metadatas
        )
    
    def update_document(self, document: str, doc_id: str, metadata: Optional[Dict] = None):
        """Update a document in the vector store"""
        if metadata is None:
            metadata = {}
        
        self.collection.update(
            documents=[document],
            ids=[doc_id],
            metadatas=[metadata]
        )
    
    def delete_document(self, doc_id: str):
        """Delete a document from the vector store"""
        try:
            self.collection.delete(ids=[doc_id])
        except Exception:
            pass  # Document might not exist
    
    def search(self, query: str, n_results: int = 5) -> List[Dict]:
        """Search for similar documents"""
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results
        )
        
        if not results["documents"] or not results["documents"][0]:
            return []
        
        formatted_results = []
        for i, doc in enumerate(results["documents"][0]):
            formatted_results.append({
                "document": doc,
                "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                "distance": results["distances"][0][i] if results["distances"] else 0.0,
                "id": results["ids"][0][i] if results["ids"] else None
            })
        
        return formatted_results
    
    def get_by_id(self, doc_id: str) -> Optional[Dict]:
        """Get document by ID"""
        try:
            results = self.collection.get(ids=[doc_id])
            if results["documents"]:
                return {
                    "document": results["documents"][0],
                    "metadata": results["metadatas"][0] if results["metadatas"] else {},
                    "id": doc_id
                }
        except Exception:
            pass
        return None
    
    def clear_all(self):
        """Clear all documents (use with caution)"""
        self.client.delete_collection(name="knowledge_base")
        try:
            self.collection = self.client.get_or_create_collection(
                name="knowledge_base",
                metadata={"hnsw:space": "cosine"}
            )
        except (TypeError, AttributeError):
            # Old API doesn't support metadata in get_or_create_collection
            self.collection = self.client.get_or_create_collection(
                name="knowledge_base"
            )


# Global vector store instance (lazy initialization)
_vector_store_instance = None

def get_vector_store() -> VectorStore:
    """Get vector store instance (lazy initialization)"""
    global _vector_store_instance
    if _vector_store_instance is None:
        try:
            _vector_store_instance = VectorStore()
        except Exception as e:
            print(f"⚠ Error initializing vector store: {e}")
            raise
    return _vector_store_instance

# Backward compatibility
vector_store = None

def _init_vector_store():
    """Initialize vector store on first access"""
    global vector_store
    if vector_store is None:
        vector_store = get_vector_store()
    return vector_store


