# frozen_string_literal: true

module LiteLLM
  module ToolHandler
    class ToolCallError < BaseError; end

    def self.call(response:, available_tools: [])
      tool_calls = response.dig("choices", 0, "message", "tool_calls")
      return response unless tool_calls&.any?

      # Build a mapping of function names to tools
      @available_tools = {}
      available_tools.each do |tool|
        tool.class.function_definitions.each do |function_name, definition|
          @available_tools[definition[:name]] = tool
        end
      end

      LiteLLM.logger.debug "Available tool functions: #{@available_tools.keys.inspect}"

      messages = [
        response.dig("choices", 0, "message").merge("role" => "assistant")
      ]

      tool_results = execute_tool_calls(tool_calls)
      messages.concat(build_tool_messages(tool_results))

      messages
    end

    private

    def self.execute_tool_calls(tool_calls)
      tool_calls.map do |tool_call|
        function_name = tool_call.dig("function", "name")
        arguments = parse_tool_arguments(tool_call.dig("function", "arguments"))

        tool = @available_tools[function_name]

        unless tool
          raise ToolCallError,
                "Tool function '#{function_name}' not available for this request: DEBUG: #{@available_tools.inspect}"
        end

        output = tool.execute_function(function_name, arguments)

        LiteLLM.logger.info "Tool call executed: #{function_name} with arguments: #{arguments.inspect}, output: #{output.inspect}"

        {
          tool_call_id: tool_call["id"],
          function_name: function_name,
          output: output
        }
      rescue StandardError => e
        handle_tool_execution_error(tool_call, e)
      end
    end

    def self.parse_tool_arguments(arguments_json)
      return {} if arguments_json.nil? || arguments_json.empty?

      JSON.parse(arguments_json).transform_keys(&:to_sym)
    rescue JSON::ParserError => e
      raise ToolCallError.new("Invalid tool call arguments: #{e.message}", e)
    end

    def self.build_tool_messages(results)
      results.map do |result|
        {
          "role" => "tool",
          "tool_call_id" => result[:tool_call_id],
          "name" => result[:function_name],
          "content" => result[:output].to_s
        }
      end
    end

    def self.handle_tool_execution_error(tool_call, error)
      function_name = tool_call.dig("function", "name")
      arguments = tool_call.dig("function", "arguments")

      LiteLLM.logger.error "Tool call failed: #{function_name} with arguments: #{arguments.inspect}"
      LiteLLM.logger.error "Error details: #{error.class} - #{error.message}"
      LiteLLM.logger.error error.backtrace.join("\n") if error.backtrace

      {
        tool_call_id: tool_call["id"],
        function_name: function_name,
        output: "Error executing tool: #{error.message}"
      }
    end
  end
end
