# frozen_string_literal: true

module LiteLLM
  class Client
    Error = Class.new(StandardError)
    ConfigurationError = Class.new(Error)
    ConnectionError = Class.new(Error)
    TimeoutError = Class.new(Error)
    APIError = Class.new(Error)

    # @param config [LiteLLM::Config] Configuration object
    def initialize(config = LiteLLM.configuration)
      @config = config
      @messages = []

      validate_configuration!
    end

    # Get a list of available models from the LiteLLM server
    # @return [Array<String>] Array of model names
    def models
      response = make_get_request("/models")
      parsed_response = handle_json_response(response)
      parsed_response["data"].map { |model| model["id"] }
    end

    # Make a completion request
    # @param messages [Array<Hash>] Array of message objects
    # @param model [String, nil] Optional model override
    # @param stream [Boolean] Whether to stream the response
    # @param tools [Array<ToolDefinition>] Array of tools available for the request
    # @return [Hash, Enumerator] Response data or stream
    def completion(messages:, model: nil, stream: false, tools: [], system_message: nil, **options,
                   &block)
      @messages = messages.dup
      @messages = [{ role: "system", content: system_message }] + @messages if system_message

      payload = build_payload(
        messages: @messages,
        model: model || @config.model,
        stream: stream,
        **options
      )

      payload[:tools] = build_tools_schema(tools) unless tools.empty?

      if stream
        raise ArgumentError, "Block required for streaming requests" unless block_given?

        stream_completion(payload, tools, model, &block)
      else
        non_stream_completion(payload, tools, model)
      end
    end

    # Generate embeddings for input text
    # @param input [String, Array<String>] Input text(s)
    # @param model [String, nil] Optional model override
    # @param options [Hash] Additional options to pass to the API
    # @return [Hash] Embedding response
    def embedding(input:, model: nil, dimensions: nil, **options)
      payload = build_payload(
        input: input,
        model: model || @config.embedding_model,
        dimensions: dimensions || @config.embedding_dimensions,
        **options
      )

      response = make_request("/embeddings", payload)

      handle_json_response(response).dig("data", 0, "embedding")
    end

    # Generate images from a prompt
    # @param prompt [String] Image generation prompt
    # @param options [Hash] Additional options to pass to the API
    # @return [Hash] Image generation response
    def image_generation(prompt:, model: nil, **options)
      payload = build_payload(
        prompt: prompt,
        model: model || @config.image_model,
        **options
      )

      response = make_request("/images/generations", payload)

      handle_json_response(response).dig("data", 0, "url")
    end

    private

    def stream_completion(payload, tools, model, &block)
      LiteLLM.logger.debug "Starting streaming completion request"

      make_request("/chat/completions", payload) do |content, tool_call_payload|
        if content
          block.call(content)
        elsif tool_call_payload
          handle_tool_calls(tool_call_payload, tools, model, true, &block)
        end
      end

      LiteLLM.logger.debug "Completed streaming request"
    end

    def non_stream_completion(payload, tools, model)
      response = make_request("/chat/completions", payload)
      response = handle_json_response(response, "/chat/completions")

      tool_calls = response.dig("choices", 0, "message", "tool_calls")

      if tool_calls&.any?
        LiteLLM.logger.debug "Tool calls detected in non-streaming response"
        handle_tool_calls(response, tools, model, false)
      else
        response.dig("choices", 0, "message", "content")
      end
    end

    def build_payload(**params)
      params = params
               .transform_keys(&:to_sym)
               .compact

      LiteLLM.logger.debug "--------------------------------"
      LiteLLM.logger.debug "LiteLLM Request: #{params.to_json}"
      LiteLLM.logger.debug "--------------------------------"

      params
    end

    def build_tools_schema(tools)
      tools.flat_map do |tool|
        unless tool.is_a?(Module) || tool.respond_to?(:to_tool_format)
          raise ArgumentError, "Tool must include ToolDefinition module"
        end

        tool.to_tool_format
      end
    end

    def make_request(endpoint, payload, method: :post, &block)
      request_id = SecureRandom.uuid
      log_request(request_id, endpoint, payload)

      response = connection.send(method, endpoint) do |req|
        req.headers["X-Request-ID"] = request_id
        req.body = payload.to_json if method == :post
        req.options.on_data = Streaming.process_stream(&block) if payload[:stream]
      end

      log_response(request_id, response)
      response
    rescue StandardError => e
      log_error(request_id, e)
      raise
    end

    # Make a GET request to the specified endpoint
    # @param endpoint [String] The API endpoint to call
    # @param payload [Hash] The request payload
    # @param block [Proc] Optional block for handling streaming responses
    # @return [Faraday::Response] The API response
    def make_get_request(endpoint, payload = {}, &)
      make_request(endpoint, payload, method: :get, &)
    end

    # Make a POST request to the specified endpoint
    # @param endpoint [String] The API endpoint to call
    # @param payload [Hash] The request payload
    # @param block [Proc] Optional block for handling streaming responses
    # @return [Faraday::Response] The API response
    def make_post_request(endpoint, payload = {}, &)
      make_request(endpoint, payload, method: :post, &)
    end

    def handle_tool_calls(response_data, tools, model, stream, &)
      LiteLLM.logger.debug "Handling tool calls, stream=#{stream}"

      begin
        LiteLLM.logger.debug "Tool call response: #{response_data.inspect}"

        # Add tool-related messages to conversation history
        tool_messages = ToolHandler.call(response: response_data, available_tools: tools)
        @messages += tool_messages

        LiteLLM.logger.debug "Tool handler generated messages: #{@messages.inspect}"

        completion(messages: @messages, model: model, tools: tools, stream: stream, &)
      rescue StandardError => e
        LiteLLM.logger.error "Error in handle_tool_calls: #{e.message}\n#{e.backtrace.join("\n")}"
        raise
      end
    end

    def handle_json_response(response, endpoint = nil)
      LiteLLM.logger.debug <<~LOG
        --------------------------------
        LiteLLM RAW Response: #{response.inspect}
        --------------------------------
      LOG

      parsed_response = ErrorHandler.parse_json(response.body)

      ErrorHandler.validate_completion_response(parsed_response) if endpoint == "/chat/completions"

      parsed_response
    end

    def connection
      @connection ||= Faraday.new(url: @config.base_url) do |f|
        f.request :json
        f.response :raise_error

        f.headers["X-LITELLM-TIMEOUT"] = @config.timeout.to_s

        f.headers["Authorization"] = "Bearer #{@config.api_key}" if @config.api_key

        f.headers["X-LITELLM-ENABLE-MESSAGE-REDACTION"] = true if @config.enable_message_redaction

        f.options.timeout = @config.timeout
        f.adapter Faraday.default_adapter
      end
    rescue URI::InvalidURIError => e
      ErrorHandler.handle_error(
        ConfigurationError,
        "Invalid base URL: #{@config.base_url}",
        e,
        debug: @config.debug
      )
    end

    def validate_configuration!
      raise ConfigurationError, "Base URL is required" if @config.base_url.nil?

      validate_base_url!
    end

    def validate_base_url!
      uri = URI.parse(@config.base_url)
      unless uri.scheme&.match?(/\Ahttps?\z/)
        raise ConfigurationError, "Base URL must be HTTP or HTTPS"
      end
    rescue URI::InvalidURIError => e
      raise ConfigurationError, "Invalid base URL: #{e.message}"
    end

    def log_request(request_id, endpoint, payload)
      LiteLLM.logger.info("[#{request_id}] Request to #{endpoint}")
      return unless LiteLLM.configuration.debug

      LiteLLM.logger.debug("[#{request_id}] Payload: #{payload.inspect}")
    end

    def log_response(request_id, response)
      LiteLLM.logger.info("[#{request_id}] Response received")
      return unless LiteLLM.configuration.debug

      LiteLLM.logger.debug("[#{request_id}] Response: #{response.inspect}")
    end

    def log_error(request_id, e)
      LiteLLM.logger.error("[#{request_id}] Error: #{e.message}")
      return unless LiteLLM.configuration.debug

      LiteLLM.logger.debug("[#{request_id}] Backtrace: #{e.backtrace.join("\n")}")
    end
  end
end
