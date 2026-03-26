"""
parser.py — OpenAPI/YAML spec parser → normalized endpoint list.

Usage:
    from parser import parse_openapi_spec
    endpoints = parse_openapi_spec("path/to/openapi.json")

Supports OpenAPI 3.x in JSON or YAML format.
Also supports a raw URL list format for simple APIs.
"""

import json
import sys
from pathlib import Path
from typing import Any


def _resolve_ref(ref: str, spec: dict) -> dict:
    """Resolve a $ref pointer within the spec."""
    parts = ref.lstrip("#/").split("/")
    node = spec
    for part in parts:
        node = node.get(part, {})
    return node


def _extract_schema_example(schema: dict, spec: dict, depth: int = 0) -> Any:
    """Recursively extract an example value from a JSON Schema."""
    if depth > 5:
        return None
    if not schema:
        return None

    if "$ref" in schema:
        schema = _resolve_ref(schema["$ref"], spec)

    if "example" in schema:
        return schema["example"]

    schema_type = schema.get("type", "object")

    if schema_type == "object":
        result = {}
        for prop_name, prop_schema in schema.get("properties", {}).items():
            result[prop_name] = _extract_schema_example(prop_schema, spec, depth + 1)
        return result

    if schema_type == "array":
        item_schema = schema.get("items", {})
        return [_extract_schema_example(item_schema, spec, depth + 1)]

    defaults = {
        "string": "string",
        "integer": 0,
        "number": 0.0,
        "boolean": True,
    }
    return defaults.get(schema_type, None)


def _parse_parameters(params: list, spec: dict) -> tuple[dict, dict]:
    """Split parameters into query params and headers."""
    query_params = {}
    headers = {}
    for param in params:
        if "$ref" in param:
            param = _resolve_ref(param["$ref"], spec)
        location = param.get("in", "")
        name = param.get("name", "")
        example = param.get("example", param.get("schema", {}).get("example", ""))
        if location == "query":
            query_params[name] = str(example) if example else ""
        elif location == "header":
            headers[name] = str(example) if example else ""
    return query_params, headers


def _parse_request_body(request_body: dict, spec: dict) -> dict | None:
    """Extract body template from requestBody."""
    if not request_body:
        return None
    content = request_body.get("content", {})
    for mime, media in content.items():
        if "json" in mime:
            schema = media.get("schema", {})
            return _extract_schema_example(schema, spec)
    return None


def parse_openapi_spec(file_path: str) -> list[dict]:
    """
    Parse an OpenAPI 3.x spec file and return a list of normalized endpoints.

    Each endpoint has:
        api_name, base_url, path, method, summary, description,
        query_params, headers, body_template, tags
    """
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"Spec file not found: {file_path}")

    text = path.read_text(encoding="utf-8")

    if path.suffix in (".yaml", ".yml"):
        try:
            import yaml  # type: ignore
            spec = yaml.safe_load(text)
        except ImportError:
            raise ImportError("PyYAML is required for YAML files: pip install pyyaml")
    else:
        spec = json.loads(text)

    # Resolve base URL
    servers = spec.get("servers", [])
    base_url = servers[0].get("url", "") if servers else ""

    # API metadata
    info = spec.get("info", {})
    api_name = info.get("title", "Unknown API")
    tags = [tag.get("name", "") for tag in spec.get("tags", [])]

    endpoints = []
    paths = spec.get("paths", {})

    for path_str, path_item in paths.items():
        if "$ref" in path_item:
            path_item = _resolve_ref(path_item["$ref"], spec)

        # Path-level parameters
        path_level_params = path_item.get("parameters", [])

        for method in ["get", "post", "put", "patch", "delete", "head", "options"]:
            operation = path_item.get(method)
            if not operation:
                continue

            summary = operation.get("summary", "")
            description = operation.get("description", summary)
            op_tags = operation.get("tags", tags[:1] if tags else [])

            # Merge path-level + operation-level parameters
            params = path_level_params + operation.get("parameters", [])
            query_params, headers = _parse_parameters(params, spec)

            # Request body
            body_template = _parse_request_body(
                operation.get("requestBody", {}), spec
            )

            endpoints.append({
                "api_name": api_name,
                "base_url": base_url,
                "path": path_str,
                "method": method.upper(),
                "summary": summary,
                "description": description,
                "query_params": query_params,
                "headers": headers,
                "body_template": body_template,
                "tags": op_tags,
            })

    return endpoints


def parse_raw_endpoint_list(file_path: str) -> list[dict]:
    """
    Parse a simple JSON list of endpoints (alternative to OpenAPI spec).

    Expected format:
    [
        {
            "api_name": "Example API",
            "base_url": "https://api.example.com",
            "path": "/v1/data",
            "method": "GET",
            "summary": "Fetch data",
            ...
        }
    ]
    """
    path = Path(file_path)
    return json.loads(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python parser.py <openapi_spec.json>")
        sys.exit(1)
    result = parse_openapi_spec(sys.argv[1])
    print(json.dumps(result, indent=2))
