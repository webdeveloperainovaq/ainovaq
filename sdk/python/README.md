# ainovaq (Python SDK)

Python client for [Ainovaq](https://ainovaq.com), the AI venture studio. Use it to read Ainovaq's services, blog articles, search results and contact details. No API key needed, and no dependencies.

```sh
pip install ainovaq
```

```python
from ainovaq import Ainovaq

client = Ainovaq()

for s in client.services():
    print(s["name"], "-", s["summary"], s["url"])

print(client.service("gtm")["description"])

for a in client.search_articles("go-to-market", limit=3):
    print(a["title"], a["url"])

article = client.article("startup-mvp-development")   # by slug or numeric ID, includes HTML
print(client.categories())
print(client.search("venture studio"))                 # articles and pages
print(client.contact())
```

There's also a small command line: `python -m ainovaq services`.

Under the hood the SDK calls Ainovaq's public, read-only MCP server (`https://ainovaq.com/mcp`) and content API (`https://ainovaq.com/wp-json/wp/v2`, [OpenAPI](https://ainovaq.com/openapi.json)). Errors raise `ainovaq.AinovaqError`.

Docs: https://ainovaq.com/developers/ · MIT licensed
