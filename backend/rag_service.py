"""RAG service using Gemini API"""
import google.generativeai as genai
from typing import List, Dict, Optional
from config import settings
from vector_store import get_vector_store


class RAGService:
    """Retrieval Augmented Generation service"""
    
    def __init__(self):
        """Initialize Gemini API"""
        if not settings.gemini_api_key:
            raise ValueError("GEMINI_API_KEY is not set in environment variables")
        
        genai.configure(api_key=settings.gemini_api_key)
        # Use latest available model (gemini-2.0-flash is fast and free)
        # Try newer models first, fallback to older ones
        model_names = [
            'gemini-2.0-flash',
            'gemini-2.5-flash',
            'gemini-1.5-flash',
            'gemini-flash-latest',
            'gemini-pro-latest',
            'gemini-pro'
        ]
        
        self.model = None
        for model_name in model_names:
            try:
                self.model = genai.GenerativeModel(model_name)
                print(f"✓ Using model: {model_name}")
                break
            except Exception as e:
                continue
        
        if self.model is None:
            raise ValueError("No compatible Gemini model found. Please check your API key and available models.")
    
    def generate_response(
        self, 
        query: str, 
        context_documents: List[str] = None,
        max_tokens: int = 1000
    ) -> str:
        """Generate response using RAG"""
        # Build context from retrieved documents
        if context_documents:
            context = "\n\n".join([
                f"Documento {i+1}:\n{doc}" 
                for i, doc in enumerate(context_documents)
            ])
            
            prompt = f"""Eres un asistente experto que ayuda a los empleados de una tienda online con preguntas sobre procedimientos, condiciones de envío, manuales y funcionamiento.

Contexto relevante de la base de conocimiento:
{context}

Pregunta del usuario: {query}

Instrucciones:
- Responde de manera clara, concisa y profesional
- Usa SOLO la información proporcionada en el contexto
- Si la información no está en el contexto, di amablemente que no tienes esa información específica
- Si es necesario, proporciona pasos numerados o listas
- Responde en el mismo idioma que la pregunta
- Sé específico y práctico en tus respuestas

Respuesta:"""
        else:
            prompt = f"""Eres un asistente experto que ayuda a los empleados de una tienda online.

Pregunta del usuario: {query}

Nota: No tengo información específica en la base de conocimiento sobre esta pregunta. Puedo ayudarte con información general o sugerirte que contactes con un supervisor si necesitas información específica.

Responde de manera amable y profesional."""
        
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Lo siento, hubo un error al generar la respuesta: {str(e)}"
    
    def chat(self, query: str, n_results: int = 5) -> Dict:
        """Chat with RAG - retrieve relevant documents and generate response"""
        # Retrieve relevant documents
        vector_store = get_vector_store()
        search_results = vector_store.search(query, n_results=n_results)
        
        # Extract documents
        context_documents = []
        sources = []
        source_urls = []  # Collect unique URLs
        
        for result in search_results:
            if result["document"]:
                context_documents.append(result["document"])
                metadata = result.get("metadata", {})
                if metadata:
                    sources.append(metadata)
                    # Collect URLs from metadata
                    url = metadata.get("url", "").strip()
                    title = metadata.get("title", "").strip()
                    if url and url not in [s["url"] for s in source_urls]:
                        source_urls.append({
                            "url": url,
                            "title": title or "Documento de referencia"
                        })
        
        # Generate response
        response_text = self.generate_response(query, context_documents)
        
        # Append source links to the response
        if source_urls:
            response_text += "\n\n**Documentos de referencia:**\n"
            for i, source in enumerate(source_urls, 1):
                if source["url"]:
                    response_text += f"{i}. [{source['title']}]({source['url']})\n"
        elif sources:
            # If we have sources but no URLs, still mention them
            response_text += "\n\n*Basado en información de la base de conocimiento*"
        
        return {
            "response": response_text,
            "sources": sources,
            "context_count": len(context_documents)
        }


# Global RAG service instance
rag_service = None

def get_rag_service() -> RAGService:
    """Get RAG service instance (lazy initialization)"""
    global rag_service
    if rag_service is None:
        rag_service = RAGService()
    return rag_service


