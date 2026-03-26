"""
enricher.py — Enrich normalized endpoints with:
  - Unique IDs
  - Cleaned-up documentation
  - Sample payload formatting
  - Expected response scaffold
  - Auth requirement hints
"""

import json
import re
import uuid


AUTH_KEYWORDS = [
    "api_key", "apikey", "x-api-key", "authorization", "bearer",
    "token", "access_token", "client_id", "client_secret", "oauth",
]


def _detect_auth_required(endpoint: dict) -> dict:
    """Try to detect if auth headers are required."""
    all_text = json.dumps(endpoint).lower()
    for kw in AUTH_KEYWORDS:
        if kw in all_text:
            return {"required": True, "type": "apiKey", "hint": "Add your API key in the Authorization header"}
    return {"required": False, "type": "none", "hint": ""}


def _clean_description(text: str) -> str:
    """Strip markdown/HTML from description for clean display."""
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = text.replace("**", "").replace("__", "").replace("*", "")
    return text.strip()


def enrich_endpoint(endpoint: dict, index: int) -> dict:
    """Enrich a single normalized endpoint dict."""
    enriched = dict(endpoint)

    # Generate stable-ish ID from api name + path + method
    raw = f"{endpoint.get('api_name','')}-{endpoint.get('method','')}-{endpoint.get('path','')}"
    derived_id = str(uuid.uuid5(uuid.NAMESPACE_URL, raw))
    enriched["id"] = derived_id

    # Clean description
    enriched["description"] = _clean_description(
        endpoint.get("description") or endpoint.get("summary") or ""
    )

    # Body template → JSON string for display
    body = endpoint.get("body_template")
    if body:
        enriched["body_template"] = json.dumps(body, indent=2)
    else:
        enriched["body_template"] = None

    # Auth hint
    enriched["auth"] = _detect_auth_required(endpoint)

    # Sample expected response (generic scaffold)
    enriched["sample_response"] = {
        "status": 200,
        "body": "{}"
    }

    # Ensure required fields exist
    enriched.setdefault("query_params", {})
    enriched.setdefault("headers", {})

    return enriched


def enrich_endpoints(endpoints: list[dict]) -> list[dict]:
    """Enrich all endpoints in place."""
    return [enrich_endpoint(ep, i) for i, ep in enumerate(endpoints)]


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python enricher.py <tagged_endpoints.json>")
        sys.exit(1)
    data = json.loads(open(sys.argv[1]).read())
    result = enrich_endpoints(data)
    print(json.dumps(result, indent=2))
