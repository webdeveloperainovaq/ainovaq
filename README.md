# Ainovaq: SDKs, CLI and MCP server

Official client libraries and tools for **[Ainovaq](https://ainovaq.com)**, the full-stack AI venture studio (Build, GTM, Digital, Talent, Infra).

Everything here uses Ainovaq's free, public, read-only API: no API key and no signup.

| Folder | What it is | Install |
| --- | --- | --- |
| [`cli/`](cli/) | JavaScript / TypeScript SDK and the `ainovaq` command-line tool, including a local MCP server | `npm install ainovaq` · `npx ainovaq services` |
| [`sdk/python/`](sdk/python/) | Python SDK | `pip install ainovaq` (coming soon) |
| [`sdk/ruby/`](sdk/ruby/) | Ruby SDK | `gem install ainovaq` (coming soon) |
| [`mcp-registry/`](mcp-registry/) | The Ainovaq MCP server's entry in the official MCP Registry (`com.ainovaq/mcp`) | |

## MCP server

Connect Claude, Cursor or any MCP client to **`https://ainovaq.com/mcp`** (Streamable HTTP, no authentication):

```json
{
  "mcpServers": {
    "ainovaq": { "type": "http", "url": "https://ainovaq.com/mcp" }
  }
}
```

Or run it locally over stdio: `npx ainovaq mcp-server`.

Tools: `list_services`, `get_service_details`, `search_blog`, `get_contact_info`. All are read-only.

Listed on the [official MCP Registry](https://registry.modelcontextprotocol.io/v0/servers?search=com.ainovaq/mcp) and [Glama](https://glama.ai/mcp/connectors/com.ainovaq/mcp).

## API

- Developer docs: https://ainovaq.com/developers/
- OpenAPI 3.0 description: https://ainovaq.com/openapi.json
- API index: https://ainovaq.com/api
- A2A agent card: https://ainovaq.com/.well-known/agent-card.json

## Quick start

```js
import { Ainovaq } from 'ainovaq';

const ainovaq = new Ainovaq();
for (const s of await ainovaq.services()) console.log(s.name, s.url);
```

```sh
npx ainovaq search "go-to-market" -n 3
```

## Contact

info@ainovaq.com · https://ainovaq.com/book-a-demo/

MIT License © Ainovaq Solutions LLC
