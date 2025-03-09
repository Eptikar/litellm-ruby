# LiteLLM Ruby Client

A Ruby client for [LiteLLM](https://docs.litellm.ai/docs) with support for completions, embeddings, and image generation.

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

## Starting Local LiteLLM Server

You can run a liteLLM server locally by placing this sample config.yaml file:

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

Then you can simply start LiteLLM as a docker container:

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
  config.base_url = 'http://localhost:8000'
  config.timeout = 30
  config.model = 'gpt-3.5-turbo'
end
```

## Usage

### Chat Completions

Basic completion:

```ruby
client = LiteLLM::Client.new

response = client.completion(
  messages: [{ role: 'user', content: 'Hello, how are you?' }],
)

puts response
```

Streaming completion:

```ruby
client = LiteLLM::Client.new

client.completion(
  messages: [
    { role: 'user', content: 'Write a story' }
  ],
  stream: true,
) { |chunk| print chunk }
```

With additional parameters:

```ruby
response = client.completion(
  messages: [
    { role: 'user', content: 'Translate to French: Hello, world!' }
  ],
  model: 'gpt-4',
  temperature: 0.7,
  max_tokens: 100,
)
```

### Embeddings

Generate embeddings for text:

```ruby
vector = client.embedding(
  input: 'The quick brown fox jumps over the lazy dog',
  model: 'text-embedding-ada-002',
)
```

### Image Generation

Generate images from text descriptions:

```ruby
image_url = client.image_generation(
  prompt: 'A beautiful sunset over the ocean',
  size: '1024x1024',
  n: 1,
)
```

## Additional LiteLLM Features  

LiteLLM offers additional features through its API, including **Audio, Assistants, Files, Batch**, and [more](https://docs.litellm.ai/docs/).  
This gem currently implements the features we needed, and I plan to add more as time permits.  

Contributions are always welcome! If you'd like to help expand the gem, please check the [Contributing](#contributing) section.

## Author  
* [Mohamed Nimir](https://www.linkedin.com/in/mohamednimir/)

## Inspirations

* [ruby-openai](https://github.com/alexrudall/ruby-openai)
* [langchainrb](https://github.com/patterns-ai-core/langchainrb)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Eptikar/litellm-ruby. 

## License

The gem is available as open source under the terms of the [MIT](https://opensource.org/license/MIT).