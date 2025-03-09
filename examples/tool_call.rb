# frozen_string_literal: true

# Tool call example

require "litellm"

LiteLLM.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "http://localhost:8000"
  config.model = "openai/gpt-4o"
  config.debug = true
end

client = LiteLLM::Client.new

# Basic custom greeting tool call example
class CustomGreetingTool
  include LiteLLM::Utils::ToolDefinition

  define_function :generate_custom_greeting,
                  description: "Generate a custom greeting with unique replies" do
    property :name, type: "string", description: "The name of the user"
  end

  def generate_custom_greeting(name:)
    [
      "Ahoy, #{name}! Ready to conquer the day?",
      "Greetings, #{name}! The adventure begins now!",
      "Salutations, #{name}! Time to make today epic!"
    ].sample
  end
end

response = client.completion(
  messages: [{ role: "user", content: "Give me a greeting, My name is Ahmed!" }],
  tools: [CustomGreetingTool.new]
)

puts response
