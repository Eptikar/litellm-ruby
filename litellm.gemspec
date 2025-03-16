# frozen_string_literal: true

require_relative "lib/litellm/version"

Gem::Specification.new do |spec|
  spec.name          = "litellm"
  spec.version       = File.read(File.expand_path("VERSION", __dir__)).strip
  spec.summary       = "LiteLLM Ruby Client."
  spec.description   = "A Ruby client for LiteLLM (the LLM proxy/gateway)."
  spec.authors       = ["Mohamed Nimir"]
  spec.homepage      = "https://github.com/eptikar/litellm-ruby"
  spec.email         = ["mohamed.nimir@eptikar.com"]
  spec.license       = "MIT"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.require_paths = ["lib"]
  spec.files         = Dir["LICENSE.txt", "CHANGELOG.md", "VERSION", "lib/**/*.rb"]

  spec.add_dependency "event_stream_parser", ">= 0.3.0", "< 2.0.0"
  spec.add_dependency "faraday", ">= 1"

  spec.metadata = {
    "source_code_uri" => "https://github.com/Eptikar/litellm-ruby",
    "changelog_uri" => "https://github.com/Eptikar/litellm-ruby/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/Eptikar/litellm-ruby/issues"
  }

  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")
end
