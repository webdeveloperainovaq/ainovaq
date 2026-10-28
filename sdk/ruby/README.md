# ainovaq (Ruby SDK)

Ruby client for [Ainovaq](https://ainovaq.com), the AI venture studio. Use it to read Ainovaq's services, blog articles, search results and contact details. No API key needed, and no dependencies.

```sh
gem install ainovaq
```

```ruby
require "ainovaq"

client = Ainovaq::Client.new

client.services.each { |s| puts "#{s['name']}: #{s['summary']} #{s['url']}" }
puts client.service("gtm")["description"]

client.search_articles("go-to-market", limit: 3).each { |a| puts a["title"], a["url"] }

article = client.article("startup-mvp-development")  # by slug or numeric ID, includes HTML
p client.categories
p client.search("venture studio")                     # articles and pages
p client.contact
```

Under the hood the SDK calls Ainovaq's public, read-only MCP server (`https://ainovaq.com/mcp`) and content API (`https://ainovaq.com/wp-json/wp/v2`, [OpenAPI](https://ainovaq.com/openapi.json)). Errors raise `Ainovaq::Error`.

Docs: https://ainovaq.com/developers/ · MIT licensed
