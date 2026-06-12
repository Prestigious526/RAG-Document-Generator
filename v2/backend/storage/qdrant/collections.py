import httpx


COLLECTIONS = {
    "document_chunks": 768,
    "image_chunks": 768,
    "table_chunks": 768,
    "summaries": 768,
    "templates": 768,
}


def ensure_qdrant_collections(qdrant_url: str) -> dict:
    base = qdrant_url.rstrip("/")
    results = {}
    with httpx.Client(timeout=20) as client:
        for name, size in COLLECTIONS.items():
            response = client.put(
                f"{base}/collections/{name}",
                json={"vectors": {"size": size, "distance": "Cosine"}},
            )
            results[name] = {"status_code": response.status_code, "ok": response.is_success}
    return results
