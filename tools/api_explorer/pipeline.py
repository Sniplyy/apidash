"""
pipeline.py — Master orchestrator for the API Explorer data pipeline.

Usage:
    # Parse a single OpenAPI spec
    python pipeline.py --spec path/to/openapi.json

    # Regenerate from the built-in raw seed data
    python pipeline.py --seed

    # Combine multiple specs
    python pipeline.py --spec spec1.yaml --spec spec2.json

The final output is written to ../../assets/api_registry.json
(relative to this file), which is bundled in the Flutter app.
"""

import argparse
import json
import sys
from pathlib import Path

# Local modules
sys.path.insert(0, str(Path(__file__).parent))
from parser import parse_openapi_spec          # noqa: E402
from tagger import tag_endpoints               # noqa: E402
from enricher import enrich_endpoints          # noqa: E402
from template_gen import generate_registry     # noqa: E402

# Default output location
ASSETS_DIR = Path(__file__).parent.parent.parent / "assets"
OUTPUT_FILE = ASSETS_DIR / "api_registry.json"

# Built-in seed data (hand-crafted, used when --seed flag is passed)
SEED_ENDPOINTS: list[dict] = [
    # ── AI ──────────────────────────────────────────────────────────────
    {
        "api_name": "OpenAI",
        "base_url": "https://api.openai.com",
        "path": "/v1/chat/completions",
        "method": "POST",
        "summary": "Chat Completion",
        "description": "Send a list of messages and get an AI-generated reply. Supports GPT-4o, GPT-4, GPT-3.5-turbo and more.",
        "query_params": {},
        "headers": {"Authorization": "Bearer YOUR_API_KEY", "Content-Type": "application/json"},
        "body_template": '{\n  "model": "gpt-4o-mini",\n  "messages": [\n    {"role": "user", "content": "Hello!"}\n  ]\n}',
        "tags": ["AI"],
    },
    {
        "api_name": "OpenAI",
        "base_url": "https://api.openai.com",
        "path": "/v1/images/generations",
        "method": "POST",
        "summary": "Generate Image (DALL·E)",
        "description": "Generate images from a text prompt using DALL·E 3.",
        "query_params": {},
        "headers": {"Authorization": "Bearer YOUR_API_KEY", "Content-Type": "application/json"},
        "body_template": '{\n  "model": "dall-e-3",\n  "prompt": "A futuristic city at sunset",\n  "n": 1,\n  "size": "1024x1024"\n}',
        "tags": ["AI"],
    },
    {
        "api_name": "Google Gemini",
        "base_url": "https://generativelanguage.googleapis.com",
        "path": "/v1beta/models/gemini-2.0-flash:generateContent",
        "method": "POST",
        "summary": "Generate Content",
        "description": "Generate text using Google Gemini 2.0 Flash model.",
        "query_params": {"key": "YOUR_API_KEY"},
        "headers": {"Content-Type": "application/json"},
        "body_template": '{\n  "contents": [\n    {"parts": [{"text": "Explain quantum computing in simple terms."}]}\n  ]\n}',
        "tags": ["AI"],
    },
    # ── Weather ──────────────────────────────────────────────────────────
    {
        "api_name": "OpenWeatherMap",
        "base_url": "https://api.openweathermap.org",
        "path": "/data/2.5/weather",
        "method": "GET",
        "summary": "Current Weather",
        "description": "Get the current weather conditions for any city worldwide.",
        "query_params": {"q": "London", "appid": "YOUR_API_KEY", "units": "metric"},
        "headers": {},
        "body_template": None,
        "tags": ["Weather"],
    },
    {
        "api_name": "OpenWeatherMap",
        "base_url": "https://api.openweathermap.org",
        "path": "/data/2.5/forecast",
        "method": "GET",
        "summary": "5 Day Weather Forecast",
        "description": "Get a 5-day weather forecast with 3-hour steps for any location.",
        "query_params": {"q": "London", "appid": "YOUR_API_KEY", "units": "metric"},
        "headers": {},
        "body_template": None,
        "tags": ["Weather"],
    },
    {
        "api_name": "Open-Meteo",
        "base_url": "https://api.open-meteo.com",
        "path": "/v1/forecast",
        "method": "GET",
        "summary": "Weather Forecast (Free, No Key)",
        "description": "Free weather forecast API with no API key required. Provides hourly & daily data.",
        "query_params": {"latitude": "52.52", "longitude": "13.41", "current_weather": "true"},
        "headers": {},
        "body_template": None,
        "tags": ["Weather"],
    },
    # ── Finance ──────────────────────────────────────────────────────────
    {
        "api_name": "CoinGecko",
        "base_url": "https://api.coingecko.com",
        "path": "/api/v3/simple/price",
        "method": "GET",
        "summary": "Crypto Price",
        "description": "Get current prices of multiple cryptocurrencies in any currency.",
        "query_params": {"ids": "bitcoin,ethereum", "vs_currencies": "usd"},
        "headers": {},
        "body_template": None,
        "tags": ["Finance"],
    },
    {
        "api_name": "CoinGecko",
        "base_url": "https://api.coingecko.com",
        "path": "/api/v3/coins/markets",
        "method": "GET",
        "summary": "Crypto Markets List",
        "description": "Get a paginated list of all cryptocurrencies with market data.",
        "query_params": {"vs_currency": "usd", "order": "market_cap_desc", "per_page": "10"},
        "headers": {},
        "body_template": None,
        "tags": ["Finance"],
    },
    {
        "api_name": "ExchangeRate-API",
        "base_url": "https://v6.exchangerate-api.com",
        "path": "/v6/YOUR_API_KEY/latest/USD",
        "method": "GET",
        "summary": "Currency Exchange Rates",
        "description": "Get real-time currency exchange rates relative to a base currency.",
        "query_params": {},
        "headers": {},
        "body_template": None,
        "tags": ["Finance"],
    },
    # ── Developer ────────────────────────────────────────────────────────
    {
        "api_name": "GitHub",
        "base_url": "https://api.github.com",
        "path": "/repos/{owner}/{repo}",
        "method": "GET",
        "summary": "Get Repository Info",
        "description": "Fetch metadata about a GitHub repository including stars, forks, and language.",
        "query_params": {},
        "headers": {"Authorization": "Bearer YOUR_GITHUB_TOKEN", "Accept": "application/vnd.github+json"},
        "body_template": None,
        "tags": ["Developer"],
    },
    {
        "api_name": "GitHub",
        "base_url": "https://api.github.com",
        "path": "/search/repositories",
        "method": "GET",
        "summary": "Search Repositories",
        "description": "Search GitHub repositories by keyword, language, or stars.",
        "query_params": {"q": "flutter stars:>1000", "sort": "stars", "per_page": "10"},
        "headers": {"Accept": "application/vnd.github+json"},
        "body_template": None,
        "tags": ["Developer"],
    },
    {
        "api_name": "JSONPlaceholder",
        "base_url": "https://jsonplaceholder.typicode.com",
        "path": "/posts",
        "method": "GET",
        "summary": "List Posts",
        "description": "Free fake REST API for testing. Returns 100 sample blog posts.",
        "query_params": {},
        "headers": {},
        "body_template": None,
        "tags": ["Developer"],
    },
    {
        "api_name": "JSONPlaceholder",
        "base_url": "https://jsonplaceholder.typicode.com",
        "path": "/posts",
        "method": "POST",
        "summary": "Create Post",
        "description": "Simulate creating a post via a fake REST API (returns mocked response).",
        "query_params": {},
        "headers": {"Content-Type": "application/json"},
        "body_template": '{\n  "title": "My new post",\n  "body": "Post content here",\n  "userId": 1\n}',
        "tags": ["Developer"],
    },
    # ── News ─────────────────────────────────────────────────────────────
    {
        "api_name": "NewsAPI",
        "base_url": "https://newsapi.org",
        "path": "/v2/top-headlines",
        "method": "GET",
        "summary": "Top Headlines",
        "description": "Get breaking news headlines from 80,000+ global sources.",
        "query_params": {"country": "us", "apiKey": "YOUR_API_KEY", "pageSize": "10"},
        "headers": {},
        "body_template": None,
        "tags": ["News"],
    },
    {
        "api_name": "NewsAPI",
        "base_url": "https://newsapi.org",
        "path": "/v2/everything",
        "method": "GET",
        "summary": "Search Articles",
        "description": "Search through millions of articles from 80,000+ sources.",
        "query_params": {"q": "technology", "apiKey": "YOUR_API_KEY", "language": "en"},
        "headers": {},
        "body_template": None,
        "tags": ["News"],
    },
    # ── Maps ─────────────────────────────────────────────────────────────
    {
        "api_name": "OpenCage Geocoding",
        "base_url": "https://api.opencagedata.com",
        "path": "/geocode/v1/json",
        "method": "GET",
        "summary": "Forward Geocoding",
        "description": "Convert a human-readable address to geographic coordinates.",
        "query_params": {"q": "Eiffel Tower, Paris", "key": "YOUR_API_KEY"},
        "headers": {},
        "body_template": None,
        "tags": ["Maps"],
    },
    {
        "api_name": "ip-api",
        "base_url": "http://ip-api.com",
        "path": "/json/{query}",
        "method": "GET",
        "summary": "IP Geolocation",
        "description": "Get geographic location, ISP, and timezone from an IP address. Free, no key needed.",
        "query_params": {},
        "headers": {},
        "body_template": None,
        "tags": ["Maps"],
    },
    # ── Communication ─────────────────────────────────────────────────────
    {
        "api_name": "Mailchimp Marketing",
        "base_url": "https://<dc>.api.mailchimp.com",
        "path": "/3.0/lists",
        "method": "GET",
        "summary": "Get Mailing Lists",
        "description": "Retrieve all mailing lists / audiences in your Mailchimp account.",
        "query_params": {},
        "headers": {"Authorization": "Bearer YOUR_API_KEY"},
        "body_template": None,
        "tags": ["Communication"],
    },
    # ── Media ────────────────────────────────────────────────────────────
    {
        "api_name": "Pexels",
        "base_url": "https://api.pexels.com",
        "path": "/v1/search",
        "method": "GET",
        "summary": "Search Photos",
        "description": "Search for high-quality free stock photos on Pexels.",
        "query_params": {"query": "nature", "per_page": "10"},
        "headers": {"Authorization": "YOUR_API_KEY"},
        "body_template": None,
        "tags": ["Media"],
    },
    {
        "api_name": "GIPHY",
        "base_url": "https://api.giphy.com",
        "path": "/v1/gifs/search",
        "method": "GET",
        "summary": "Search GIFs",
        "description": "Search the GIPHY library for animated GIFs by keyword.",
        "query_params": {"api_key": "YOUR_API_KEY", "q": "cats", "limit": "10"},
        "headers": {},
        "body_template": None,
        "tags": ["Media"],
    },
    # ── Data ─────────────────────────────────────────────────────────────
    {
        "api_name": "REST Countries",
        "base_url": "https://restcountries.com",
        "path": "/v3.1/all",
        "method": "GET",
        "summary": "All Countries",
        "description": "Get data about all countries: name, capital, currencies, languages, flags and more.",
        "query_params": {"fields": "name,capital,currencies,languages,flags"},
        "headers": {},
        "body_template": None,
        "tags": ["Data"],
    },
    {
        "api_name": "Open Library",
        "base_url": "https://openlibrary.org",
        "path": "/search.json",
        "method": "GET",
        "summary": "Search Books",
        "description": "Search the Open Library catalog for books, authors, and editions.",
        "query_params": {"q": "harry potter", "limit": "10"},
        "headers": {},
        "body_template": None,
        "tags": ["Data"],
    },
    {
        "api_name": "NASA APOD",
        "base_url": "https://api.nasa.gov",
        "path": "/planetary/apod",
        "method": "GET",
        "summary": "Astronomy Picture of the Day",
        "description": "Get NASA's Astronomy Picture of the Day along with its explanation.",
        "query_params": {"api_key": "DEMO_KEY"},
        "headers": {},
        "body_template": None,
        "tags": ["Data"],
    },
    # ── Health ────────────────────────────────────────────────────────────
    {
        "api_name": "Open Food Facts",
        "base_url": "https://world.openfoodfacts.org",
        "path": "/api/v0/product/{barcode}.json",
        "method": "GET",
        "summary": "Get Food Product by Barcode",
        "description": "Get nutritional information for a food product using its barcode.",
        "query_params": {},
        "headers": {},
        "body_template": None,
        "tags": ["Health"],
    },
    # ── Other ─────────────────────────────────────────────────────────────
    {
        "api_name": "Joke API",
        "base_url": "https://v2.jokeapi.dev",
        "path": "/joke/Any",
        "method": "GET",
        "summary": "Random Joke",
        "description": "Get a random joke from the JokeAPI. Supports filtering by category, language and blacklist flags.",
        "query_params": {"safe-mode": "true"},
        "headers": {},
        "body_template": None,
        "tags": ["Other"],
    },
]


def run_pipeline(spec_files: list[str] = None, use_seed: bool = False) -> None:
    """Run the full pipeline and write api_registry.json."""
    all_endpoints: list[dict] = []

    if use_seed:
        print(f"✓ Loaded {len(SEED_ENDPOINTS)} seed endpoints")
        all_endpoints.extend(SEED_ENDPOINTS)

    if spec_files:
        for spec_file in spec_files:
            print(f"  Parsing: {spec_file}")
            parsed = parse_openapi_spec(spec_file)
            all_endpoints.extend(parsed)
            print(f"  + {len(parsed)} endpoints from {spec_file}")

    if not all_endpoints:
        print("⚠ No endpoints to process. Use --seed or --spec <file>")
        return

    print(f"\nTagging {len(all_endpoints)} endpoints...")
    tagged = tag_endpoints(all_endpoints)

    print("Enriching endpoints...")
    enriched = enrich_endpoints(tagged)

    output = str(OUTPUT_FILE)
    print(f"\nGenerating registry → {output}")
    generate_registry(enriched, output)

    # Print category summary
    from collections import Counter
    counts = Counter(ep["category"] for ep in enriched)
    print("\nCategory breakdown:")
    for cat, count in sorted(counts.items()):
        print(f"  {cat}: {count}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="API Explorer data pipeline")
    parser.add_argument("--spec", nargs="*", default=[], help="OpenAPI spec files to parse")
    parser.add_argument("--seed", action="store_true", help="Include built-in seed data")
    args = parser.parse_args()

    use_seed = args.seed or not args.spec
    run_pipeline(spec_files=args.spec or [], use_seed=use_seed)
