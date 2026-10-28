"""Ainovaq Python SDK.

A small client for Ainovaq's public, read-only interfaces: the MCP server at /mcp and the content
API at /wp-json/wp/v2. No API key needed and no dependencies beyond the standard library.

    from ainovaq import Ainovaq
    client = Ainovaq()
    for s in client.services():
        print(s["name"], s["url"])
"""

from __future__ import annotations

import html
import itertools
import json
import re
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, List, Optional, Union

__all__ = ["Ainovaq", "AinovaqError", "__version__"]
__version__ = "1.0.0"

DEFAULT_BASE_URL = "https://ainovaq.com"


class AinovaqError(Exception):
    """Raised when a request to Ainovaq fails."""

    def __init__(self, message: str, status: Optional[int] = None) -> None:
        super().__init__(message)
        self.status = status


def _text(value: Any) -> str:
    """HTML or a WordPress {"rendered": ...} field -> plain text."""
    if isinstance(value, dict):
        value = value.get("rendered", "")
    value = re.sub(r"<[^>]*>", " ", str(value or ""))
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def _article(p: Dict[str, Any]) -> Dict[str, Any]:
    out = {
        "id": p.get("id"),
        "slug": p.get("slug"),
        "title": _text(p.get("title")),
        "url": p.get("link"),
        "date": p.get("date"),
        "summary": _text(p.get("excerpt")),
        "categories": p.get("categories"),
    }
    if isinstance(p.get("content"), dict):
        out["html"] = p["content"].get("rendered")
    return out


class Ainovaq:
    """Client for the Ainovaq API and MCP server."""

    def __init__(self, base_url: str = DEFAULT_BASE_URL, timeout: float = 20.0, user_agent: Optional[str] = None) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.user_agent = user_agent or "ainovaq-python/" + __version__
        self._ids = itertools.count(1)

    # ---- transport -------------------------------------------------------------------------

    def _request(self, url: str, data: Optional[bytes] = None, headers: Optional[Dict[str, str]] = None) -> Any:
        hdrs = {"Accept": "application/json", "User-Agent": self.user_agent}
        hdrs.update(headers or {})
        req = urllib.request.Request(url, data=data, headers=hdrs, method="POST" if data is not None else "GET")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as res:
                return json.loads(res.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raise AinovaqError("%s %s failed: HTTP %s" % (req.get_method(), url, e.code), e.code) from None
        except urllib.error.URLError as e:
            raise AinovaqError("Could not reach %s: %s" % (url, e.reason)) from None

    def _get(self, path: str, **query: Any) -> Any:
        q = {k: v for k, v in query.items() if v is not None}
        qs = "?" + urllib.parse.urlencode(q) if q else ""
        return self._request(self.base_url + "/wp-json/wp/v2" + path + qs)

    def call_tool(self, name: str, arguments: Optional[Dict[str, Any]] = None) -> Any:
        """Call a tool on the Ainovaq MCP server and return its structured result."""
        body = json.dumps({"jsonrpc": "2.0", "id": next(self._ids), "method": "tools/call", "params": {"name": name, "arguments": arguments or {}}}).encode("utf-8")
        res = self._request(self.base_url + "/mcp", body, {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"})
        if res.get("error"):
            raise AinovaqError(res["error"].get("message", "MCP error"))
        result = res.get("result") or {}
        text = "\n".join(c.get("text", "") for c in result.get("content", []))
        if result.get("isError"):
            raise AinovaqError(text or "Tool error")
        return result.get("structuredContent") or json.loads(text)

    # ---- services and contact (MCP) ------------------------------------------------------

    def services(self) -> List[Dict[str, Any]]:
        """The five services: [{id, name, type, summary, url}]."""
        return self.call_tool("list_services")["services"]

    def service(self, service_id: str) -> Dict[str, Any]:
        """One service: 'build', 'gtm', 'digital', 'talent' or 'infra'."""
        return self.call_tool("get_service_details", {"service": service_id.lower()})

    def contact(self) -> Dict[str, Any]:
        """Contact details and the booking link."""
        return self.call_tool("get_contact_info")

    # ---- content (REST) -------------------------------------------------------------------

    def search_articles(self, query: str, limit: int = 5, page: int = 1) -> List[Dict[str, Any]]:
        """Search blog articles."""
        posts = self._get("/posts", search=query, per_page=limit, page=page, _fields="id,slug,title,link,date,excerpt,categories")
        return [_article(p) for p in posts]

    def articles(self, limit: int = 10, page: int = 1, category: Optional[int] = None) -> List[Dict[str, Any]]:
        """Latest blog articles, optionally in one category ID."""
        posts = self._get("/posts", per_page=limit, page=page, categories=category, _fields="id,slug,title,link,date,excerpt,categories")
        return [_article(p) for p in posts]

    def article(self, id_or_slug: Union[int, str]) -> Optional[Dict[str, Any]]:
        """One article (with its HTML) by numeric ID or slug; None if not found."""
        if str(id_or_slug).isdigit():
            found = self._get("/posts", include=str(id_or_slug))
        else:
            found = self._get("/posts", slug=str(id_or_slug))
        return _article(found[0]) if found else None

    def categories(self) -> List[Dict[str, Any]]:
        """Blog categories: [{id, name, slug, count}]."""
        return [{"id": c["id"], "name": _text(c["name"]), "slug": c["slug"], "count": c.get("count")} for c in self._get("/categories", per_page=100, _fields="id,name,slug,count")]

    def search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search articles and pages: [{id, title, url, type}]."""
        return [{"id": r["id"], "title": _text(r.get("title")), "url": r.get("url"), "type": r.get("subtype")} for r in self._get("/search", search=query, per_page=limit)]
