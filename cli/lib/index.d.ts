export interface AinovaqOptions { baseUrl?: string; fetch?: typeof fetch; userAgent?: string }
export interface Service { id: string; name: string; type: string; summary: string; url: string }
export interface ServiceDetails { id: string; name: string; type: string; description: string; url: string; book_a_call: string }
export interface Contact { company: string; email: string; phone: string; book_a_call: string; linkedin: string }
export interface Article { id: number; slug: string; title: string; url: string; date: string; summary: string; html?: string; categories?: number[] }
export interface Category { id: number; name: string; slug: string; count: number }
export interface SearchResult { id: number; title: string; url: string; type: 'post' | 'page' }
export type ServiceId = 'build' | 'gtm' | 'digital' | 'talent' | 'infra';

export declare class AinovaqError extends Error { status?: number }
export declare class Ainovaq {
  constructor(options?: AinovaqOptions);
  baseUrl: string;
  callTool<T = unknown>(name: string, args?: Record<string, unknown>): Promise<T>;
  services(): Promise<Service[]>;
  service(id: ServiceId): Promise<ServiceDetails>;
  contact(): Promise<Contact>;
  searchArticles(query: string, options?: { limit?: number; page?: number }): Promise<Article[]>;
  articles(options?: { limit?: number; page?: number; category?: number }): Promise<Article[]>;
  article(idOrSlug: number | string): Promise<Article | null>;
  categories(): Promise<Category[]>;
  search(query: string, options?: { limit?: number }): Promise<SearchResult[]>;
}
export declare const VERSION: string;
export default Ainovaq;
