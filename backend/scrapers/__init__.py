"""Scrapers module"""
from .zendesk_scraper import ZendeskScraper, scrape_zendesk_articles
from .url_scraper import URLScraper, scrape_url_for_knowledge

__all__ = [
    "ZendeskScraper",
    "scrape_zendesk_articles",
    "URLScraper",
    "scrape_url_for_knowledge"
]


