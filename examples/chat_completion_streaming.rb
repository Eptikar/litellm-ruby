# frozen_string_literal: true

# Chat completion streaming example

require "litellm"

LiteLLM.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "http://localhost:8000"
  config.model = "openai/gpt-4o"
  config.debug = false # if true the streaming stdout won't work
end

client = LiteLLM::Client.new

puts "USER: What is the capital of Oman?"

client.completion(
  messages: [{ role: "user", content: "What is the capital of Oman?" }],
  stream: true
) { |chunk| print chunk }
