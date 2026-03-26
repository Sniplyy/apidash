"""
tagger.py — Auto-tag API endpoints to categories based on
keywords found in the URL, summary, description, and existing tags.
"""

import re
from typing import Optional

# Category → keywords mapping
CATEGORY_KEYWORDS: dict[str, list[str]] = {
    "AI": [
        "ai", "ml", "model", "llm", "gpt", "gemini", "claude", "chat",
        "completion", "embedding", "inference", "openai", "anthropic",
        "generative", "artificial intelligence", "machine learning",
        "vision", "speech", "transcription", "sentiment",
    ],
    "Weather": [
        "weather", "forecast", "climate", "temperature", "humidity",
        "precipitation", "wind", "storm", "meteorolog", "atmosphere",
        "openweather", "accuweather",
    ],
    "Finance": [
        "finance", "stock", "market", "currency", "exchange", "crypto",
        "bitcoin", "ethereum", "coin", "trade", "price", "portfolio",
        "investment", "bank", "payment", "transaction", "forex",
    ],
    "Social": [
        "social", "twitter", "instagram", "facebook", "reddit", "tiktok",
        "linkedin", "post", "tweet", "follower", "user", "feed",
        "profile", "community", "share", "like", "comment",
    ],
    "Maps": [
        "map", "location", "geocod", "coordinate", "gps", "place",
        "address", "route", "direction", "navigation", "geospatial",
        "latitude", "longitude", "mapbox", "googlemaps", "here",
    ],
    "News": [
        "news", "article", "headline", "press", "media", "blog",
        "rss", "feed", "publish", "newsletter", "story",
    ],
    "Communication": [
        "email", "sms", "message", "notification", "push", "whatsapp",
        "twilio", "sendgrid", "smtp", "webhook", "slack", "discord",
        "chat", "inbox", "send",
    ],
    "E-Commerce": [
        "product", "cart", "order", "shop", "store", "inventory",
        "checkout", "shipping", "buyer", "seller", "price", "sku",
        "woocommerce", "shopify", "amazon",
    ],
    "Developer": [
        "github", "gitlab", "bitbucket", "repo", "commit", "issue",
        "pr", "pull request", "deploy", "ci", "cd", "pipeline",
        "docker", "kubernetes", "registry", "webhook", "token",
    ],
    "Data": [
        "database", "dataset", "analytics", "metric", "stat", "report",
        "export", "import", "csv", "json", "xml", "table", "query",
        "aggregate", "insight",
    ],
    "Media": [
        "image", "photo", "video", "audio", "pexels", "unsplash",
        "giphy", "youtube", "vimeo", "media", "thumbnail", "stream",
    ],
    "Health": [
        "health", "medical", "doctor", "hospital", "drug", "medicine",
        "patient", "diagnosis", "therapy", "wellness", "fitness",
    ],
    "Other": [],  # Fallback
}


def tag_endpoint(endpoint: dict) -> str:
    """
    Return the most relevant ApiCategory string for the given endpoint dict.
    Fields examined: api_name, base_url, path, summary, description, tags.
    """
    # Gather all text to search
    text_parts = [
        endpoint.get("api_name", ""),
        endpoint.get("base_url", ""),
        endpoint.get("path", ""),
        endpoint.get("summary", ""),
        endpoint.get("description", ""),
        " ".join(endpoint.get("tags", [])),
    ]
    combined_text = " ".join(text_parts).lower()
    combined_text = re.sub(r"[^a-z0-9 _/-]", " ", combined_text)

    scores: dict[str, int] = {cat: 0 for cat in CATEGORY_KEYWORDS}

    for category, keywords in CATEGORY_KEYWORDS.items():
        for kw in keywords:
            if kw in combined_text:
                scores[category] += 1

    # Remove "Other" from scoring consideration initially
    scores.pop("Other", None)

    best_category = max(scores, key=lambda c: scores[c]) if scores else "Other"
    if scores.get(best_category, 0) == 0:
        best_category = "Other"

    return best_category


def tag_endpoints(endpoints: list[dict]) -> list[dict]:
    """Assign a 'category' field to each endpoint in the list."""
    for ep in endpoints:
        ep["category"] = tag_endpoint(ep)
    return endpoints


if __name__ == "__main__":
    import json
    import sys

    if len(sys.argv) < 2:
        print("Usage: python tagger.py <endpoints.json>")
        sys.exit(1)
    data = json.loads(open(sys.argv[1]).read())
    result = tag_endpoints(data)
    print(json.dumps(result, indent=2))
