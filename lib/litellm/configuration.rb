# frozen_string_literal: true

require "logger"

module LiteLLM
  DEFAULTS = {
    base_url: "http://localhost:8000",
    timeout: 120,
    model: "gpt-4o",
    embedding_model: "text-embedding-3-large",
    image_model: "dall-e-2",
    embedding_dimensions: 1536,
    enable_message_redaction: false,
    debug: false,
    api_key: ENV.fetch("LITE_LLM_API_KEY", nil)
  }.freeze

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def logger
      configuration.logger
    end
  end

  class Configuration
    attr_reader :base_url, :timeout, :model, :embedding_model, :image_model, :embedding_dimensions,
                :debug, :logger, :enable_message_redaction, :api_key

    def initialize
      @base_url = DEFAULTS[:base_url]
      @timeout = DEFAULTS[:timeout]
      @model = DEFAULTS[:model]
      @embedding_model = DEFAULTS[:embedding_model]
      @image_model = DEFAULTS[:image_model]
      @embedding_dimensions = DEFAULTS[:embedding_dimensions]
      @enable_message_redaction = DEFAULTS[:enable_message_redaction]
      @debug = DEFAULTS[:debug]
      @api_key = DEFAULTS[:api_key]
      @logger = setup_default_logger
    end

    def base_url=(value)
      @base_url = value unless value.nil?
    end

    def timeout=(value)
      @timeout = value.to_i unless value.nil?
    end

    def model=(value)
      @model = value unless value.nil?
    end

    def embedding_model=(value)
      @embedding_model = value unless value.nil?
    end

    def image_model=(value)
      @image_model = value unless value.nil?
    end

    def enable_message_redaction=(value)
      @enable_message_redaction = value unless value.nil?
    end

    def api_key=(value)
      @api_key = value unless value.nil?
    end

    def debug=(value)
      @debug = if value.nil?
                 defined?(Rails) ? Rails.env.development? : false
               else
                 value.to_s == "true"
               end
    end

    def logger=(value)
      @logger = value if value
    end

    private

    def setup_default_logger
      logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      logger.level = debug ? Logger::DEBUG : Logger::INFO
      logger
    end
  end
end
