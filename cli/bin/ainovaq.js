#!/usr/bin/env node
'use strict';

/*
 * ainovaq: command-line tool for Ainovaq (https://ainovaq.com).
 * Talks to the public, read-only Ainovaq MCP server and content API. No account or API key needed.
 */

const { Ainovaq, VERSION } = require('../lib');
const client = new Ainovaq({ baseUrl: process.env.AINOVAQ_URL, userAgent: 'ainovaq-cli/' + VERSION });
const SITE = client.baseUrl;
const MCP = SITE + '/mcp';

const HELP = `ainovaq ${VERSION}: Ainovaq, the AI venture studio, from your terminal

Usage:
  ainovaq services                 List the five Ainovaq services
  ainovaq service <id>             Details of one service (build, gtm, digital, talent, infra)
  ainovaq search <words> [-n 5]    Search Ainovaq blog articles
  ainovaq contact                  Contact details and the booking link
  ainovaq mcp                      MCP client config for Claude, Cursor and others
  ainovaq mcp-server               Run the Ainovaq MCP server over stdio (for MCP clients)
  ainovaq --version | --help

Options:
  --json                           Print raw JSON (for scripts and agents)
  -n, --limit <1-10>               Number of search results (default 5)

Docs: ${SITE}/developers/`;

const args = process.argv.slice(2);
const json = args.includes('--json');
const rest = [];
let limit = 5;
for (let i = 0; i < args.length; i++) {
	const a = args[i];
	if (a === '--json') continue;
	if (a === '-n' || a === '--limit') { limit = Math.max(1, Math.min(10, parseInt(args[++i], 10) || 5)); continue; }
	rest.push(a);
}
const [cmd, ...params] = rest;

const mcpTool = (name, toolArgs) => client.callTool(name, toolArgs);

const wrap = (t, w = 76, pad = '    ') => {
	const out = []; let line = '';
	for (const word of String(t).split(' ')) {
		if ((line + ' ' + word).trim().length > w) { out.push(pad + line.trim()); line = word; } else line += ' ' + word;
	}
	if (line.trim()) out.push(pad + line.trim());
	return out.join('\n');
};
const print = data => console.log(JSON.stringify(data, null, 2));

async function main() {
	if (cmd === 'mcp-server') return require('../lib/mcp-stdio').runStdioServer({ baseUrl: process.env.AINOVAQ_URL, version: VERSION });
	if (!cmd || cmd === 'help' || args.includes('--help') || args.includes('-h')) return console.log(HELP);
	if (cmd === 'version' || args.includes('--version') || args.includes('-v')) return console.log(VERSION);

	switch (cmd) {
		case 'services': {
			const d = await mcpTool('list_services');
			if (json) return print(d);
			console.log('Ainovaq: one studio, five capabilities\n');
			for (const s of d.services) console.log(`  ${s.name.padEnd(8)} ${s.type}\n${wrap(s.summary)}\n    ${s.url}\n`);
			return console.log(`Details: ainovaq service <${d.services.map(s => s.id).join('|')}>`);
		}
		case 'service': {
			if (!params[0]) throw new Error('Which service? ainovaq service <build|gtm|digital|talent|infra>');
			const s = await mcpTool('get_service_details', { service: params[0].toLowerCase() });
			if (json) return print(s);
			return console.log(`${s.name} (${s.type})\n\n${wrap(s.description, 76, '')}\n\nMore:         ${s.url}\nBook a call:  ${s.book_a_call}`);
		}
		case 'search': {
			const q = params.join(' ').trim();
			if (!q) throw new Error('What should I search for? ainovaq search "go-to-market"');
			const posts = (await client.searchArticles(q, { limit })).map(p => ({ title: p.title, url: p.url, date: String(p.date || '').slice(0, 10), summary: p.summary }));
			if (json) return print({ query: q, results: posts });
			if (!posts.length) return console.log(`No Ainovaq articles found for "${q}". Browse all: ${SITE}/blog/`);
			console.log(`Ainovaq articles for "${q}":\n`);
			for (const p of posts) console.log(`  ${p.title}\n    ${p.date} · ${p.url}\n${p.summary ? wrap(p.summary.slice(0, 220) + (p.summary.length > 220 ? '…' : '')) + '\n' : ''}`);
			return;
		}
		case 'contact': {
			const c = await mcpTool('get_contact_info');
			if (json) return print(c);
			return console.log(`${c.company}\n\n  Email:        ${c.email}\n  Phone:        ${c.phone}\n  LinkedIn:     ${c.linkedin}\n  Book a call:  ${c.book_a_call}`);
		}
		case 'mcp': {
			const cfg = { mcpServers: { ainovaq: { type: 'http', url: MCP } } };
			if (json) return print(cfg);
			console.log('Add this to your MCP client config (Claude Desktop, Cursor, …):\n');
			print(cfg);
			console.log(`\nClaude Code:  claude mcp add --transport http ainovaq ${MCP}`);
			return console.log('Clients that only launch local servers:  { "command": "npx", "args": ["-y", "ainovaq", "mcp-server"] }');
		}
		default:
			throw new Error(`Unknown command "${cmd}". Run: ainovaq --help`);
	}
}

main().catch(e => {
	console.error('ainovaq: ' + (e && e.message ? e.message : e));
	process.exitCode = 1;
});
