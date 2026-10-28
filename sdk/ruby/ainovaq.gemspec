# frozen_string_literal: true

require_relative "lib/ainovaq/version"

Gem::Specification.new do |spec|
  spec.name          = "ainovaq"
  spec.version       = Ainovaq::VERSION
  spec.authors       = ["Ainovaq Solutions LLC"]
  spec.email         = ["info@ainovaq.com"]
  spec.summary       = "Ruby SDK for Ainovaq, the AI venture studio."
  spec.description   = "Read Ainovaq's services, blog articles, search results and contact details through its public API and MCP server. No API key needed."
  spec.homepage      = "https://ainovaq.com/developers/"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6"
  spec.metadata      = {
    "homepage_uri" => "https://ainovaq.com/",
    "source_code_uri" => "https://github.com/webdeveloperainovaq/ainovaq",
    "bug_tracker_uri" => "https://github.com/webdeveloperainovaq/ainovaq/issues",
    "documentation_uri" => "https://ainovaq.com/developers/"
  }
  spec.files         = Dir["lib/**/*.rb"] + ["README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
