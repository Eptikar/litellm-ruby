# frozen_string_literal: true

require "litellm"

LiteLLM.configure do |config|
  config.base_url = "http://localhost:8000"
  config.image_model = "dall-e-2"
end

client = LiteLLM::Client.new

url = client.image_generation(prompt: "A beautiful sunset over a calm ocean")

if url
  path = "/tmp/litellm_image.png"

  File.binwrite(path, Faraday.get(url).body)

  puts "Image saved to #{path}"
else
  puts "Failed to generate image"
end
