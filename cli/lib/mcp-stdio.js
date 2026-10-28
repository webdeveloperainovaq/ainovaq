'use strict';

/*
 * Ainovaq MCP server over stdio: `npx ainovaq mcp-server`.
 *
 * For MCP clients that launch local servers (Claude Desktop, Cursor, …). It reads newline-delimited
 * JSON-RPC messages on stdin, relays each one to the Ainovaq MCP server (https://ainovaq.com/mcp,
 * Streamable HTTP) and writes the answers to stdout. Only protocol messages go to stdout; logs go to stderr.
 */

const readline = require('readline');

function runStdioServer(options = {}) {
	const base = (options.baseUrl || process.env.AINOVAQ_URL || 'https://ainovaq.com').replace(/\/+$/, '');
	const endpoint = base + '/mcp';
	const ua = 'ainovaq-mcp-stdio/' + (options.version || '0');
	const out = obj => process.stdout.write(JSON.stringify(obj) + '\n');
	const log = msg => process.stderr.write('[ainovaq-mcp] ' + msg + '\n');

	async function relay(line) {
		let msg;
		try { msg = JSON.parse(line); } catch (e) {
			return out({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } });
		}
		const ids = (Array.isArray(msg) ? msg : [msg]).filter(m => m && m.id !== undefined).map(m => m.id);
		try {
			const res = await fetch(endpoint, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream', 'User-Agent': ua },
				body: JSON.stringify(msg)
			});
			if (res.status === 202) return; // notifications only
			const text = await res.text();
			let body;
			try { body = JSON.parse(text); } catch (e) { throw new Error('HTTP ' + res.status + ' (not JSON)'); }
			out(body);
		} catch (e) {
			log('request failed: ' + e.message);
			for (const id of ids) out({ jsonrpc: '2.0', id, error: { code: -32603, message: 'Could not reach ' + endpoint + ': ' + e.message } });
		}
	}

	// Handle messages one at a time, in order.
	let chain = Promise.resolve();
	const rl = readline.createInterface({ input: process.stdin, terminal: false });
	rl.on('line', line => {
		if (!line.trim()) return;
		chain = chain.then(() => relay(line));
	});
	rl.on('close', () => { chain.then(() => process.exit(0)); });
	log('relaying MCP over stdio to ' + endpoint);
}

module.exports = { runStdioServer };
