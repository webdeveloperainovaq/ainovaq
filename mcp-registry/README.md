# Ainovaq MCP server: registry entry

The Ainovaq MCP server runs at **`https://ainovaq.com/mcp`** (Streamable HTTP, no authentication, read-only tools). It is listed in the official MCP Registry as **`com.ainovaq/mcp`**.

| File | What it is |
| --- | --- |
| `server.remote.json` | The registry entry that is published: the remote server only |
| `server.json` | The same entry plus the `ainovaq` npm package (`npx ainovaq mcp-server`), for when the package is listed too |
| `publish.sh` | Signs in to the registry by domain (`ainovaq.com`) and publishes `server.remote.json` |
| `ed25519-sign.pl` | Ed25519 signing (RFC 8032) in plain Perl, used by `publish.sh`. Run `perl ed25519-sign.pl --selftest` to check it |

Domain verification: the registry reads the public key at `https://ainovaq.com/.well-known/mcp-registry-auth`. The matching private key is never stored in this repository (see `.gitignore`).

## Listings

- Official MCP Registry: https://registry.modelcontextprotocol.io/v0/servers?search=com.ainovaq/mcp
- Glama: https://glama.ai/mcp/connectors/com.ainovaq/mcp

## Connect a client

```json
{
  "mcpServers": {
    "ainovaq": { "type": "http", "url": "https://ainovaq.com/mcp" }
  }
}
```

Tools: `list_services`, `get_service_details`, `search_blog`, `get_contact_info`. Documentation: https://ainovaq.com/developers/
