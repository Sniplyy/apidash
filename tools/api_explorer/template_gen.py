"""
template_gen.py — Convert enriched endpoint list → api_registry.json
that is loaded by the Flutter app.

Output schema:
{
  "version": "1.0.0",
  "generated_at": "<ISO timestamp>",
  "categories": ["AI", "Weather", ...],
  "endpoints": [ { ... }, ... ]
}
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def generate_registry(enriched_endpoints: list[dict], output_path: str) -> None:
    """Write the api_registry.json file from enriched endpoints."""
    # Collect unique categories in order
    seen = []
    for ep in enriched_endpoints:
        cat = ep.get("category", "Other")
        if cat not in seen:
            seen.append(cat)

    # Sort categories alphabetically, keep "Other" last
    categories = sorted(c for c in seen if c != "Other")
    if "Other" in seen:
        categories.append("Other")

    registry = {
        "version": "1.0.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "categories": categories,
        "endpoints": enriched_endpoints,
    }

    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(registry, indent=2), encoding="utf-8")
    print(f"✓ Registry written to {output_path} ({len(enriched_endpoints)} endpoints)")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python template_gen.py <enriched_endpoints.json> <output_path>")
        sys.exit(1)
    data = json.loads(open(sys.argv[1]).read())
    generate_registry(data, sys.argv[2])
