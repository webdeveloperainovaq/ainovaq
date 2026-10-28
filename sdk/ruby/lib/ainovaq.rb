# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "cgi"
require_relative "ainovaq/version"

# Ruby SDK for Ainovaq (https://ainovaq.com), the AI venture studio.
#
# A small client for Ainovaq's public, read-only interfaces: the MCP server at /mcp and the content API
# at /wp-json/wp/v2. No API key needed and no dependencies beyond the standard library.
#
#   client = Ainovaq::Client.new
#   client.services.each { |s| puts "#{s['name']}: #{s['url']}" }
module Ainovaq
  DEFAULT_BASE_URL = "https://ainovaq.com"

  # Raised when a request to Ainovaq fails.
  class Error < StandardError
    attr_reader :status

    def initialize(message, status = nil)
      super(message)
      @status = status
    end
  end

  # Client for the Ainovaq API and MCP server.
  class Client
    attr_reader :base_url

    def initialize(base_url: DEFAULT_BASE_URL, timeout: 20, user_agent: nil)
      @base_url = base_url.sub(%r{/+\z}, "")
      @timeout = timeout
      @user_agent = user_agent || "ainovaq-ruby/#{VERSION}"
      @id = 0
    end

    # Calls a tool on the Ainovaq MCP server and returns its structured result.
    def call_tool(name, arguments = {})
      @id += 1
      body = { jsonrpc: "2.0", id: @id, method: "tools/call", params: { name: name, arguments: arguments } }
      res = request(URI("#{@base_url}/mcp"), body)
      raise Error, res["error"]["message"] if res["error"]

      result = res["result"] || {}
      text = (result["content"] || []).map { |c| c["text"].to_s }.join("\n")
      raise Error, (text.empty? ? "Tool error" : text) if result["isError"]

      result["structuredContent"] || JSON.parse(text)
    end

    # The five services: [{ "id", "name", "type", "summary", "url" }].
    def services
      call_tool("list_services")["services"]
    end

    # One service: "build", "gtm", "digital", "talent" or "infra".
    def service(id)
      call_tool("get_service_details", { service: id.to_s.downcase })
    end

    # Contact details and the booking link.
    def contact
      call_tool("get_contact_info")
    end

    # Search blog articles.
    def search_articles(query, limit: 5, page: 1)
      get("/posts", search: query, per_page: limit, page: page, _fields: "id,slug,title,link,date,excerpt,categories").map { |p| article_hash(p) }
    end

    # Latest blog articles, optionally in one category ID.
    def articles(limit: 10, page: 1, category: nil)
      get("/posts", per_page: limit, page: page, categories: category, _fields: "id,slug,title,link,date,excerpt,categories").map { |p| article_hash(p) }
    end

    # One article (with its HTML) by numeric ID or slug; nil if not found.
    def article(id_or_slug)
      found = if id_or_slug.to_s.match?(/\A\d+\z/)
                get("/posts", include: id_or_slug.to_s)
              else
                get("/posts", slug: id_or_slug.to_s)
              end
      found.empty? ? nil : article_hash(found.first)
    end

    # Blog categories: [{ "id", "name", "slug", "count" }].
    def categories
      get("/categories", per_page: 100, _fields: "id,name,slug,count").map do |c|
        { "id" => c["id"], "name" => text(c["name"]), "slug" => c["slug"], "count" => c["count"] }
      end
    end

    # Search articles and pages: [{ "id", "title", "url", "type" }].
    def search(query, limit: 10)
      get("/search", search: query, per_page: limit).map do |r|
        { "id" => r["id"], "title" => text(r["title"]), "url" => r["url"], "type" => r["subtype"] }
      end
    end

    private

    def get(path, query = {})
      q = query.reject { |_, v| v.nil? }
      uri = URI("#{@base_url}/wp-json/wp/v2#{path}")
      uri.query = URI.encode_www_form(q) unless q.empty?
      request(uri)
    end

    def request(uri, body = nil)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      req = body ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req["Accept"] = body ? "application/json, text/event-stream" : "application/json"
      req["User-Agent"] = @user_agent
      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      res = http.request(req)
      raise Error.new("#{req.method} #{uri.path} failed: HTTP #{res.code}", res.code.to_i) unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
      raise Error, "Could not reach #{uri.host}: #{e.message}"
    end

    def text(value)
      value = value["rendered"] if value.is_a?(Hash)
      CGI.unescapeHTML(value.to_s.gsub(/<[^>]*>/, " ")).gsub(/&#(\d+);/) { [Regexp.last_match(1).to_i].pack("U") }.gsub(/\s+/, " ").strip
    end

    def article_hash(p)
      h = {
        "id" => p["id"], "slug" => p["slug"], "title" => text(p["title"]), "url" => p["link"],
        "date" => p["date"], "summary" => text(p["excerpt"]), "categories" => p["categories"]
      }
      h["html"] = p["content"]["rendered"] if p["content"].is_a?(Hash)
      h
    end
  end
end
