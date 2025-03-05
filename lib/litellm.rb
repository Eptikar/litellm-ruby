# frozen_string_literal: true

require 'faraday'
require 'event_stream_parser'
require 'json'
require 'logger'

require_relative 'litellm/version'
require_relative 'litellm/configuration'
require_relative 'litellm/streaming'
require_relative 'litellm/client'
require_relative 'litellm/errors'
require_relative 'litellm/tool_handler'
require_relative 'litellm/utils/tool_definition'

module LiteLLM
  class Error < StandardError; end

  module Utils
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration
      @configuration = Configuration.new
    end

    def client
      @client ||= Client.new
    end

    def completion(*args)
      client.completion(*args)
    end

    def embedding(*args)
      client.embedding(*args)
    end

    def image_generation(*args)
      client.image_generation(*args)
    end

    def logger
      configuration.logger
    end

    def debug?
      configuration.debug
    end
  end
end
