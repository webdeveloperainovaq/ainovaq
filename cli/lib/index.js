'use strict';

/*
 * Ainovaq JavaScript SDK: a small client for Ainovaq's public, read-only interfaces
 * (the MCP server at /mcp and the content API at /wp-json/wp/v2). No API key needed. Node 18+ or any
 * runtime with fetch.
 */

const DEFAULT_BASE_URL = 'https://ainovaq.com';
const VERSION = '1.2.0';

class AinovaqError extends Error {
	constructor(message, status) {
		super(message);
		this.name = 'AinovaqError';
		this.status = status;
	}
}

const decode = s => String(s || '')
	.replace(/<[^>]*>/g, ' ')
	.replace(/&#8217;|&rsquo;/g, '’').replace(/&#8216;|&lsquo;/g, '‘')
	.replace(/&#8211;|&ndash;/g, '–').replace(/&#8212;|&mdash;/g, '—')
	.replace(/&#8220;|&#8221;|&quot;/g, '"').replace(/&#038;|&amp;/g, '&')
	.replace(/&[a-z0-9#]+;/gi, ' ').replace(/\s+/g, ' ').trim();

const toArticle = p => ({
	id: p.id,
	slug: p.slug,
	title: decode(p.title && p.title.rendered),
	url: p.link,
	date: p.date,
	summary: decode(p.excerpt && p.excerpt.rendered),
	html: p.content ? p.content.rendered : undefined,
	categories: p.categories
});

class Ainovaq {
	/**
	 * @param {{ baseUrl?: string, fetch?: typeof fetch, userAgent?: string }} [options]
	 */
	constructor(options = {}) {
		this.baseUrl = (options.baseUrl || DEFAULT_BASE_URL).replace(/\/+$/, '');
		this._fetch = options.fetch || globalThis.fetch;
		if (typeof this._fetch !== 'function') throw new AinovaqError('No fetch available: use Node 18+ or pass { fetch }');
		this._ua = options.userAgent || 'ainovaq-js/' + VERSION;
		this._id = 0;
	}

	async _get(path, query) {
		const qs = query ? '?' + new URLSearchParams(Object.entries(query).filter(([, v]) => v !== undefined && v !== null)).toString() : '';
		const res = await this._fetch(this.baseUrl + '/wp-json/wp/v2' + path + qs, { headers: { Accept: 'application/json', 'User-Agent': this._ua } });
		if (!res.ok) throw new AinovaqError(`GET ${path} failed: HTTP ${res.status}`, res.status);
		return res.json();
	}

	/** Calls a tool on the Ainovaq MCP server and returns its structured result. */
	async callTool(name, args = {}) {
		const res = await this._fetch(this.baseUrl + '/mcp', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream', 'User-Agent': this._ua },
			body: JSON.stringify({ jsonrpc: '2.0', id: ++this._id, method: 'tools/call', params: { name, arguments: args } })
		});
		if (!res.ok) throw new AinovaqError(`MCP tool ${name} failed: HTTP ${res.status}`, res.status);
		const body = await res.json();
		if (body.error) throw new AinovaqError(body.error.message);
		const r = body.result || {};
		const text = (r.content || []).map(c => c.text || '').join('\n');
		if (r.isError) throw new AinovaqError(text || 'Tool error');
		return r.structuredContent || JSON.parse(text);
	}

	/** The five services: [{ id, name, type, summary, url }]. */
	async services() {
		return (await this.callTool('list_services')).services;
	}

	/** One service: 'build' | 'gtm' | 'digital' | 'talent' | 'infra'. */
	async service(id) {
		return this.callTool('get_service_details', { service: String(id).toLowerCase() });
	}

	/** Contact details and the booking link. */
	async contact() {
		return this.callTool('get_contact_info');
	}

	/** Search blog articles. */
	async searchArticles(query, { limit = 5, page = 1 } = {}) {
		const posts = await this._get('/posts', { search: query, per_page: limit, page, _fields: 'id,slug,title,link,date,excerpt,categories' });
		return posts.map(toArticle);
	}

	/** Latest blog articles. */
	async articles({ limit = 10, page = 1, category } = {}) {
		const posts = await this._get('/posts', { per_page: limit, page, categories: category, _fields: 'id,slug,title,link,date,excerpt,categories' });
		return posts.map(toArticle);
	}

	/** One article (with its HTML) by numeric ID or slug; null if not found. */
	async article(idOrSlug) {
		const list = /^\d+$/.test(String(idOrSlug)) ? await this._get('/posts', { include: idOrSlug }) : await this._get('/posts', { slug: idOrSlug });
		return list.length ? toArticle(list[0]) : null;
	}

	/** Blog categories: [{ id, name, slug, count }]. */
	async categories() {
		const list = await this._get('/categories', { per_page: 100, _fields: 'id,name,slug,count' });
		return list.map(c => ({ id: c.id, name: decode(c.name), slug: c.slug, count: c.count }));
	}

	/** Search articles and pages: [{ id, title, url, type }]. */
	async search(query, { limit = 10 } = {}) {
		const list = await this._get('/search', { search: query, per_page: limit });
		return list.map(r => ({ id: r.id, title: decode(r.title), url: r.url, type: r.subtype }));
	}
}

module.exports = { Ainovaq, AinovaqError, VERSION };
module.exports.default = Ainovaq;
