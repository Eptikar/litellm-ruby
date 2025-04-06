# frozen_string_literal: true

require "dotenv/load"
require "vcr"
require "active_support/core_ext/string"
require "bundler/setup"
require "fileutils"
require "webmock/rspec"

require "litellm"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.default_cassette_options = {
    record: ENV["CI"] ? :none : :new_episodes
  }

  FileUtils.mkdir_p(config.cassette_library_dir)

  config.allow_http_connections_when_no_cassette = true

  # Filter out API keys from the recorded cassettes
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV.fetch("OPENAI_API_KEY", nil) }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV.fetch("ANTHROPIC_API_KEY", nil) }
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV.fetch("GEMINI_API_KEY", nil) }
  config.filter_sensitive_data("<DEEPSEEK_API_KEY>") { ENV.fetch("DEEPSEEK_API_KEY", nil) }

  config.filter_sensitive_data("<AWS_ACCESS_KEY_ID>") { ENV.fetch("AWS_ACCESS_KEY_ID", nil) }
  config.filter_sensitive_data("<AWS_SECRET_ACCESS_KEY>") do
    ENV.fetch("AWS_SECRET_ACCESS_KEY", nil)
  end
  config.filter_sensitive_data("<AWS_REGION>") { ENV.fetch("AWS_REGION", "us-west-2") }
  config.filter_sensitive_data("<AWS_SESSION_TOKEN>") { ENV.fetch("AWS_SESSION_TOKEN", nil) }

  config.filter_sensitive_data("<OPENAI_ORGANIZATION>") do |interaction|
    interaction.response.headers["Openai-Organization"]&.first
  end
  config.filter_sensitive_data("<X_REQUEST_ID>") do |interaction|
    interaction.response.headers["X-Request-Id"]&.first
  end
  config.filter_sensitive_data("<REQUEST_ID>") do |interaction|
    interaction.response.headers["Request-Id"]&.first
  end
  config.filter_sensitive_data("<CF_RAY>") do |interaction|
    interaction.response.headers["Cf-Ray"]&.first
  end

  # Filter cookies
  config.before_record do |interaction|
    if interaction.response.headers["Set-Cookie"]
      interaction.response.headers["Set-Cookie"] = interaction.response.headers["Set-Cookie"].map do
        "<COOKIE>"
      end
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around do |example|
    cassette_name = example.full_description.parameterize(separator: "_").delete_prefix("litellm_")
    VCR.use_cassette(cassette_name) do
      example.run
    end
  end
end

RSpec.shared_context "with configured LiteLLM" do
  DEFAULT_MODELS = ["gpt-3.5-turbo", "dall-e-2", "text-embedding-3"].freeze

  before do
    LiteLLM.configure do |config|
      config.base_url = "http://localhost:8000"
      config.model = "gpt-3.5-turbo"
      config.embedding_model = "text-embedding-3-small"
      config.image_model = "dall-e-2"
    end

    @client = LiteLLM::Client.new
  end
end
