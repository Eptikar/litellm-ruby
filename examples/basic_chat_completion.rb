# frozen_string_literal: true

# Basic chat completion example

require "litellm"

LiteLLM.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "http://localhost:8000"
  config.model = "openai/gpt-4o"
  config.debug = true
end

client = LiteLLM::Client.new

response = client.completion(messages: [{ role: "user", content: "Hello, how are you?" }])

puts response
