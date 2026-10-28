#!/bin/bash
# Publishes the Ainovaq MCP server (remote only, https://ainovaq.com/mcp) to the official MCP Registry,
# signing in with domain verification: https://ainovaq.com/.well-known/mcp-registry-auth must serve the
# public key of registry-key (the theme does this). Needs only curl and perl (ed25519-sign.pl).
set -euo pipefail
cd "$(dirname "$0")"
FILE="${1:-server.remote.json}"
REG=https://registry.modelcontextprotocol.io
echo "auth file: $(curl -s https://ainovaq.com/.well-known/mcp-registry-auth)"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SIG=$(perl ed25519-sign.pl registry-key.seed.hex "$TS")
TOKEN=$(curl -s -X POST "$REG/v0/auth/http" -H "Content-Type: application/json" \
  -d "{\"domain\":\"ainovaq.com\",\"timestamp\":\"$TS\",\"signed_timestamp\":\"$SIG\"}" \
  | perl -MJSON::PP -e 'local $/; my $d=decode_json(<STDIN>); print $d->{registry_token} // die("login failed: ".JSON::PP->new->encode($d)."\n")')
echo "signed in to the registry"
curl -s -X POST "$REG/v0/publish" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --data-binary @"$FILE"
echo
