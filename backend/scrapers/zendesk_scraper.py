"""Zendesk Knowledge Base scraper"""
import requests
from typing import List, Dict, Optional
from config import settings
import json


class ZendeskScraper:
    """Scraper for Zendesk Knowledge Base"""
    
    def __init__(self):
        """Initialize Zendesk scraper"""
        self.subdomain = settings.zendesk_subdomain
        self.email = settings.zendesk_email
        self.api_token = settings.zendesk_api_token
        self.base_url = f"https://{self.subdomain}.zendesk.com/api/v2"
        
        if not all([self.subdomain, self.email, self.api_token]):
            raise ValueError("Zendesk credentials not configured in environment variables")
    
    def _make_request(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Make authenticated request to Zendesk API"""
        url = f"{self.base_url}/{endpoint}"
        auth = (f"{self.email}/token", self.api_token)
        
        try:
            response = requests.get(url, auth=auth, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching from Zendesk: {e}")
            raise
    
    def get_all_articles(self) -> List[Dict]:
        """Get all articles from Zendesk Knowledge Base"""
        articles = []
        page = 1
        per_page = 100
        
        while True:
            try:
                response = self._make_request(
                    "help_center/articles.json",
                    params={"per_page": per_page, "page": page}
                )
                
                articles_batch = response.get("articles", [])
                if not articles_batch:
                    break
                
                articles.extend(articles_batch)
                
                # Check if there are more pages
                if len(articles_batch) < per_page:
                    break
                
                page += 1
                
            except Exception as e:
                print(f"Error fetching articles page {page}: {e}")
                break
        
        return articles
    
    def get_article_by_id(self, article_id: int) -> Optional[Dict]:
        """Get a specific article by ID"""
        try:
            response = self._make_request(f"help_center/articles/{article_id}.json")
            return response.get("article")
        except Exception:
            return None
    
    def get_categories_and_sections(self) -> List[Dict]:
        """Get all categories and sections"""
        categories_data = []
        
        try:
            # Get categories
            categories_response = self._make_request("help_center/categories.json")
            categories = categories_response.get("categories", [])
            
            for category in categories:
                category_id = category["id"]
                # Get sections for each category
                sections_response = self._make_request(
                    f"help_center/categories/{category_id}/sections.json"
                )
                sections = sections_response.get("sections", [])
                
                categories_data.append({
                    "category": category,
                    "sections": sections
                })
        except Exception as e:
            print(f"Error fetching categories: {e}")
        
        return categories_data
    
    def format_article_for_storage(self, article: Dict) -> Dict:
        """Format Zendesk article for storage"""
        # Extract text content (remove HTML tags for vector storage)
        content = article.get("body", "")
        
        # Try to get clean text (basic HTML stripping)
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(content, "html.parser")
        clean_content = soup.get_text(separator="\n", strip=True)
        
        return {
            "title": article.get("title", ""),
            "content": clean_content,
            "url": article.get("html_url", ""),
            "source": "zendesk",
            "source_id": str(article.get("id", "")),
            "metadata": json.dumps({
                "author_id": article.get("author_id"),
                "section_id": article.get("section_id"),
                "locale": article.get("locale"),
                "updated_at": article.get("updated_at"),
                "created_at": article.get("created_at"),
                "vote_sum": article.get("vote_sum", 0),
            })
        }


def scrape_zendesk_articles() -> List[Dict]:
    """Main function to scrape all Zendesk articles"""
    scraper = ZendeskScraper()
    articles = scraper.get_all_articles()
    
    formatted_articles = []
    for article in articles:
        formatted = scraper.format_article_for_storage(article)
        formatted_articles.append(formatted)
    
    return formatted_articles


