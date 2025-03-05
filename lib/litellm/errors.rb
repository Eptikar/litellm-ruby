# frozen_string_literal: true

module LiteLLM
  class BaseError < StandardError
    attr_reader :original_error

    def initialize(message = nil, original_error = nil)
      super(message)
      @original_error = original_error
    end

    def set_debug_backtrace(debug_mode)
      return unless @original_error

      set_backtrace(
        debug_mode ? @original_error.backtrace : [@original_error.backtrace.first]
      )
    end
  end

  class ConfigurationError < BaseError; end
  class APIError < BaseError; end
  class TimeoutError < BaseError; end
  class ConnectionError < BaseError; end
  class ToolCallError < BaseError; end
  class InsufficientQuotaError < APIError; end
  class RateLimitError < APIError; end
  class AuthenticationError < APIError; end
  class ValidationError < APIError; end

  module ErrorHandler
    def self.handle_error(error_class, message, original_error = nil)
      error = error_class.new(message, original_error)
      error.set_debug_backtrace(LiteLLM.debug?)
      raise error
    end

    def self.handle_api_error(error)
      error_body = begin
        parse_json(error.response[:body])
      rescue StandardError
        nil
      end
      error_message = error_body&.dig("error", "message") || error.message

      case error.response[:status]
      when 401
        handle_error(AuthenticationError, "Authentication failed: #{error_message}", error)
      when 422
        handle_error(ValidationError, "Validation failed: #{error_message}", error)
      when 429
        if error_body&.dig("error", "type") == "insufficient_quota"
          handle_error(InsufficientQuotaError, "API quota exceeded", error)
        else
          handle_error(RateLimitError, "Rate limit exceeded", error)
        end
      else
        handle_error(APIError, "API request failed (#{error.response[:status]}): #{error_message}",
                     error)
      end
    end

    def self.validate_completion_response(response)
      return if response["choices"]&.first&.dig("message")

      raise APIError, "Invalid response format from server"
    end

    def self.configuration_error_message(api_key, base_url)
      [
        ("API key not configured" if api_key.nil?),
        ("Base URL not configured" if base_url.nil?)
      ].compact.join(" and ")
    end

    def self.handle_tool_error(message, original_error = nil)
      error = ToolCallError.new(message, original_error)
      error.set_debug_backtrace(LiteLLM.debug?)
      raise error
    end

    private

    def self.parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      handle_error(APIError, "Invalid JSON response from server: #{e.message}", e)
    end

    def self.log_debug_response(response)
      <<~LOG
        --------------------------------
        LiteLLM RAW Response: #{response.inspect}
        --------------------------------
      LOG
    end
  end
end
