# ainovaq

Command-line tool for [Ainovaq](https://ainovaq.com), the AI venture studio. From your terminal you can:
- browse Ainovaq's services
- search the Ainovaq blog
- get contact details
- connect the Ainovaq MCP server to your AI tools

No account or API key needed.

```sh
npx ainovaq services
```

Or install it globally:

```sh
npm install -g ainovaq
```

Requires Node.js 18 or newer.

## Commands

| Command | What it does |
|---|---|
| `ainovaq services` | List the five services: Build, GTM, Digital, Talent, Infra |
| `ainovaq service <id>` | Details of one service, e.g. `ainovaq service gtm` |
| `ainovaq search <words> [-n 5]` | Search Ainovaq blog articles, e.g. `ainovaq search "mvp timeline"` |
| `ainovaq contact` | Email, phone, LinkedIn and the link to book a free consultation |
| `ainovaq mcp` | MCP client config for Claude, Cursor and other MCP clients |
| `ainovaq mcp-server` | Run the Ainovaq MCP server over stdio, for clients that launch local servers |

Add `--json` to any command for machine-readable output (for scripts and AI agents).

## JavaScript / TypeScript SDK

The same package is also a library (types included):

```js
const { Ainovaq } = require('ainovaq');   // or: import { Ainovaq } from 'ainovaq'

const client = new Ainovaq();
const services = await client.services();               // [{ id, name, type, summary, url }]
const gtm = await client.service('gtm');
const articles = await client.searchArticles('mvp', { limit: 3 });
const article = await client.article('startup-mvp-development');  // slug or ID, includes HTML
const categories = await client.categories();
const results = await client.search('venture studio');  // articles and pages
const contact = await client.contact();
```

Errors throw `AinovaqError`. Python (`pip install ainovaq`) and Ruby (`gem install ainovaq`) SDKs have the same methods.

## MCP server

Remote (Streamable HTTP): `https://ainovaq.com/mcp`.

Local (stdio), for clients that launch servers themselves:

```json
{ "mcpServers": { "ainovaq": { "command": "npx", "args": ["-y", "ainovaq", "mcp-server"] } } }
```

Registry name: `com.ainovaq/mcp`. Tools: `list_services`, `get_service_details`, `search_blog`, `get_contact_info`.

## Under the hood

The CLI calls Ainovaq's public, read-only interfaces:
- MCP server: `https://ainovaq.com/mcp`
- Content API: `https://ainovaq.com/wp-json/wp/v2` (OpenAPI: `https://ainovaq.com/openapi.json`)

Developer docs: https://ainovaq.com/developers/

## License

MIT © Ainovaq Solutions LLC
