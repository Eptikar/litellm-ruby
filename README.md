# LiteLLM Ruby Client

A Ruby client for LiteLLM API with support for completions, embeddings, and image generation.

_Disclaimer: This is not an official LiteLLM product. It is a community-driven project._

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'litellm'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install litellm
```

## Starting Local Litellm Server

You can run a litellm server locally by placing this sample config.yaml file:

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY

  - model_name: text-embedding-3-large
    litellm_params:
      model: openai/text-embedding-3-large
      api_key: os.environ/OPENAI_API_KEY

  - model_name: dall-e-2
    litellm_params:
      model: openai/dall-e-2
      api_key: os.environ/OPENAI_API_KEY

  - model_name: dall-e-3
    litellm_params:
      model: openai/dall-e-3
      api_key: os.environ/OPENAI_API_KEY
```

Then you can simple start litellm as a docker container:

```bash
$ docker run \
  -v $(pwd)/litellm_config.yaml:/app/config.yaml \
  -e OPENAI_API_KEY=YOUR-OPENAI-API-KEY-HERE \
  -p 8000:4000 \
  ghcr.io/berriai/litellm:main-latest \
  --config /app/config.yaml --detailed_debug
```

## Configuration

Configure the client with your API key and other optional settings:

```ruby
LiteLLM.configure do |config|
  config.api_key = 'your-api-key'
  config.base_url = 'http://localhost:8000' # Default
  config.timeout = 30 # Default in seconds
  config.model = 'gpt-3.5-turbo' # Default model
end
```

## Usage

### Chat Completions

Basic completion:

```ruby
client = LiteLLM::Client.new

response =
  client.completion(
    messages: [{ role: 'user', content: 'Hello, how are you?' }],
  )
puts response
```

Streaming completion:

```ruby
client = LiteLLM::Client.new

client.completion(
  messages: [{ role: 'user', content: 'Write a story' }],
  stream: true,
) { |chunk| print chunk }
```

With additional parameters:

```ruby
response =
  client.completion(
    messages: [{ role: 'user', content: 'Translate to French: Hello, world!' }],
    model: 'gpt-4',
    temperature: 0.7,
    max_tokens: 100,
  )
```

### Embeddings

Generate embeddings for text:

```ruby
vector =
  client.embedding(
    input: 'The quick brown fox jumps over the lazy dog',
    model: 'text-embedding-ada-002',
  )
```

### Image Generation

Generate images from text descriptions:

```ruby
image_url =
  client.image_generation(
    prompt: 'A beautiful sunset over the ocean',
    size: '1024x1024',
    n: 1,
  )
```

## License

The gem is available as open source under the terms of the [MIT](https://opensource.org/license/MIT).

## Disclaimer

This project is not affiliated with LiteLLM or Berrie AI Incorporated. It is a community-driven project.

## Contributors

- [@nimir](https://github.com/nimir) LinkedIn: [Mohamed Nimir](https://www.linkedin.com/in/mohamednimir/)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eptikar/litellm-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).
