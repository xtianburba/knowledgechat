"""Generic URL scraper for knowledge base"""
import requests
from bs4 import BeautifulSoup
from typing import Dict, Optional, List
from urllib.parse import urlparse, urljoin
import re
from slugify import slugify


class URLScraper:
    """Scraper for general URLs"""
    
    def __init__(self):
        """Initialize URL scraper"""
        self.timeout = 30
        self.max_content_length = 500000  # Max 500KB of text
    
    def scrape_url(self, url: str, follow_links: bool = False) -> Dict:
        """Scrape content from a URL"""
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
            
            response = requests.get(url, headers=headers, timeout=self.timeout)
            response.raise_for_status()
            
            # Parse HTML (try lxml first, fallback to html.parser)
            try:
                soup = BeautifulSoup(response.content, "lxml")
            except Exception:
                # Fallback to html.parser if lxml is not available
                soup = BeautifulSoup(response.content, "html.parser")
            
            # Remove script and style elements
            for script in soup(["script", "style", "nav", "header", "footer"]):
                script.decompose()
            
            # Extract title
            title = soup.find("title")
            title_text = title.get_text().strip() if title else None
            
            # If no title tag, try to get from h1 or first heading
            if not title_text:
                h1 = soup.find("h1")
                if h1:
                    title_text = h1.get_text().strip()
                else:
                    # Try first heading tag
                    heading = soup.find(["h1", "h2", "h3"])
                    if heading:
                        title_text = heading.get_text().strip()
            
            # If still no title, use URL filename or "Sin título"
            if not title_text:
                # Try to extract meaningful title from URL
                parsed = urlparse(url)
                path = parsed.path.strip("/")
                if path:
                    # Get last part of path
                    title_text = path.split("/")[-1].replace(".html", "").replace("-", " ").replace("_", " ")
                    title_text = title_text.title() if title_text else "Sin título"
                else:
                    title_text = "Sin título"
            
            # Try to find main content
            main_content = None
            
            # Common content selectors
            content_selectors = [
                "main",
                "article",
                ".content",
                "#content",
                ".main-content",
                "#main-content",
                ".post-content",
                ".entry-content"
            ]
            
            for selector in content_selectors:
                main_content = soup.select_one(selector)
                if main_content:
                    break
            
            # If no main content found, use body
            if not main_content:
                main_content = soup.find("body") or soup
            
            # Extract text
            text = main_content.get_text(separator="\n", strip=True)
            
            # Clean up text
            text = re.sub(r'\n\s*\n+', '\n\n', text)  # Multiple newlines to double
            text = text[:self.max_content_length]  # Limit length
            
            # Extract images
            images = []
            for img in soup.find_all("img"):
                img_url = img.get("src") or img.get("data-src")
                if img_url:
                    img_url = urljoin(url, img_url)
                    alt_text = img.get("alt", "")
                    images.append({
                        "url": img_url,
                        "alt": alt_text
                    })
            
            return {
                "title": title_text,
                "content": text,
                "url": url,
                "images": images[:10],  # Limit to 10 images
                "success": True
            }
            
        except requests.exceptions.RequestException as e:
            return {
                "title": "Error al obtener URL",
                "content": f"Error al acceder a la URL: {str(e)}",
                "url": url,
                "success": False,
                "error": str(e)
            }
        except Exception as e:
            return {
                "title": "Error al procesar URL",
                "content": f"Error al procesar el contenido: {str(e)}",
                "url": url,
                "success": False,
                "error": str(e)
            }
    
    def scrape_multiple_urls(self, urls: List[str]) -> List[Dict]:
        """Scrape multiple URLs"""
        results = []
        for url in urls:
            result = self.scrape_url(url)
            results.append(result)
        return results


def scrape_url_for_knowledge(url: str) -> Dict:
    """Main function to scrape URL for knowledge base"""
    scraper = URLScraper()
    result = scraper.scrape_url(url)
    
    if result["success"]:
        return {
            "title": result["title"],
            "content": result["content"],
            "url": result["url"],
            "source": "url",
            "source_id": slugify(url),
            "metadata": None
        }
    else:
        raise ValueError(f"Error scraping URL: {result.get('error', 'Unknown error')}")


