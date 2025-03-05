# frozen_string_literal: true

module LiteLLM
  module Streaming
    class StreamingError < StandardError; end

    class StreamBuffer
      attr_reader :content

      def initialize
        @content = ""
        @tool_calls = {}
        @tool_call_id = nil
      end

      def add_chunk(parsed_chunk)
        delta = parsed_chunk.dig("choices", 0, "delta")
        return process_content(delta) if delta&.key?("content")
        return process_tool_call(delta) if delta&.key?("tool_calls")

        nil
      end

      def tool_calls?
        @tool_calls.any?
      end

      def tool_call_payload
        return nil unless tool_calls?

        # Format the response to match standard API response format
        {
          "choices" => [
            {
              "message" => {
                "tool_calls" => format_tool_calls
              }
            }
          ]
        }
      end

      def reset_tool_call_id
        @tool_call_id = nil
      end

      private

      def format_tool_calls
        @tool_calls.values.map do |call|
          {
            "id" => call[:id],
            "type" => call[:type] || "function",
            "function" => {
              "name" => call[:function_name],
              "arguments" => call[:arguments]
            }
          }
        end
      end

      def process_content(delta)
        content = delta["content"].to_s
        @content += content
        content
      end

      def process_tool_call(delta)
        delta["tool_calls"].each do |tool_call|
          extract_tool_call_to_buffer(tool_call)
        end
        nil
      end

      def extract_tool_call_to_buffer(tool_call)
        @tool_call_id = tool_call["id"] if tool_call["id"]

        return unless @tool_call_id

        @tool_calls[@tool_call_id] ||= {
          id: @tool_call_id,
          index: tool_call["index"],
          function_name: nil,
          type: tool_call["type"],
          arguments: ""
        }

        if (type = tool_call["type"])
          @tool_calls[@tool_call_id][:type] = type
        end

        if (function_name = tool_call.dig("function", "name"))
          @tool_calls[@tool_call_id][:function_name] = function_name
        end

        if (new_arguments = tool_call.dig("function", "arguments"))
          @tool_calls[@tool_call_id][:arguments] += new_arguments.to_s
        end
      end
    end

    class << self
      def process_stream(&block)
        return proc {} unless block

        parser = EventStreamParser::Parser.new
        buffer = StreamBuffer.new

        proc do |chunk|
          parser.feed(chunk) do |_type, data|
            if data.strip == "[DONE]"
              handle_done(buffer, &block)
              next
            end

            process_chunk(data, buffer, &block)
          end
        end
      rescue StandardError => e
        log_error("Stream Processing Failed", e)
        raise StreamingError, "Failed to process stream: #{e.message}"
      end

      private

      def process_chunk(data, buffer, &block)
        parsed_data = JSON.parse(data)
        log_debug("Received chunk: #{data}")

        if content = buffer.add_chunk(parsed_data)
          block.call(content, nil)
        end
      rescue JSON::ParserError => e
        log_error("Stream Chunk Parsing Failed", e, data: data)
      end

      def handle_done(buffer, &block)
        return unless buffer.tool_calls?

        tool_calls_response = buffer.tool_call_payload
        log_debug("Tool call payload: #{tool_calls_response.inspect}")

        block.call(nil, tool_calls_response)
        buffer.reset_tool_call_id
      end

      def log_debug(message)
        LiteLLM.logger.debug("[Streaming] #{message}")
      end

      def log_error(message, error, **context)
        LiteLLM.logger.error("[Streaming] #{message}", error: error, **context)
      end
    end
  end
end
