# frozen_string_literal: true

# Embedding generation example

require "litellm"

LiteLLM.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "http://localhost:8000"
  config.model = "openai/gpt-4o"
  config.embedding_model = "text-embedding-3-large"
  config.debug = false
end

client = LiteLLM::Client.new

embedding = client.embedding(input: "Hello, world!")
puts embedding.size
