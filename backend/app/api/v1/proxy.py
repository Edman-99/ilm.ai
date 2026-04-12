from fastapi import APIRouter, Request, Response
from fastapi.responses import StreamingResponse
import httpx

router = APIRouter()

_TARGET = "https://app12-us-sw.ivlk.io"


@router.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def proxy(path: str, request: Request):
    url = f"{_TARGET}/{path}"

    headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in ("host", "origin", "referer")
    }
    headers["Host"] = "app12-us-sw.ivlk.io"

    body = await request.body()

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.request(
            method=request.method,
            url=url,
            headers=headers,
            content=body,
            params=dict(request.query_params),
        )

    return Response(
        content=resp.content,
        status_code=resp.status_code,
        headers={
            "Content-Type": resp.headers.get("Content-Type", "application/json"),
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
    )
