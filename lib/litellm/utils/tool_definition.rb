# frozen_string_literal: true

require "json"

module LiteLLM
  module Utils
    module ToolDefinition
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def define_function(method_name, description:, &block)
          function_definitions[method_name] = {
            name: "#{normalized_tool_name}__#{method_name}",
            description: description,
            parameters: build_parameters(&block)
          }
        end

        def function_definitions
          @function_definitions ||= {}
        end

        def normalized_tool_name
          @normalized_tool_name ||= name.split("::").last.gsub(/Tool\z/, "")
        end

        private

        def build_parameters(&block)
          return nil unless block_given?

          builder = ParameterBuilder.new
          schema = builder.build(&block)

          {
            type: "object",
            properties: schema[:properties],
            required: schema[:required],
            additionalProperties: false
          }
        end
      end

      def to_tool_format
        self.class.function_definitions.values.map do |function|
          { type: "function", function: function }
        end
      end

      def execute_function(function_name, parameters = {})
        method_name = function_name.to_s.split("__").last
        log_prefix = "[#{self.class.name}##{method_name}]"

        LiteLLM.logger.info("#{log_prefix} Called with parameters: #{parameters.inspect}")

        unless respond_to?(method_name, true)
          error_message = "Function '#{method_name}' not found in #{self.class.name}"
          LiteLLM.logger.error("#{log_prefix} #{error_message}")
          raise NoMethodError, error_message
        end

        begin
          symbolized_params = parameters.transform_keys(&:to_sym)
          validate_parameters(method_name, symbolized_params)

          result = send(method_name, **symbolized_params)

          LiteLLM.logger.info("#{log_prefix} Execution successful, returned: #{result.inspect}")
          result
        rescue ArgumentError => e
          LiteLLM.logger.error("#{log_prefix} Parameter validation failed: #{e.message}")
          raise
        rescue StandardError => e
          LiteLLM.logger.error("#{log_prefix} Execution failed: #{e.class} - #{e.message}")
          LiteLLM.logger.error("#{log_prefix} Backtrace: #{e.backtrace.first(5).join("\n")}")
          raise
        end
      end

      private

      def validate_parameters(method_name, params)
        function_def = self.class.function_definitions[method_name.to_sym]
        return unless function_def && function_def[:parameters]

        required_params = function_def[:parameters][:required] || []
        missing_params = required_params - params.keys.map(&:to_s)

        return if missing_params.empty?

        raise ArgumentError, "Missing required parameters: #{missing_params.join(', ')}"
      end

      class ParameterBuilder
        VALID_TYPES = %w[object array string number integer boolean null]

        def initialize
          @properties = {}
          @required = []
        end

        def build(&block)
          instance_eval(&block)
          { properties: @properties, required: @required }
        end

        def property(name, type:, description: nil, enum: nil, required: false, default: nil,
                     &block)
          validate_property_params(name, type, enum, required)

          prop = {
            type: type,
            description: description,
            enum: enum,
            default: default
          }.compact

          if block_given?
            nested_builder = ParameterBuilder.new
            nested_schema = nested_builder.build(&block)

            case type
            when "object"
              if nested_schema[:properties].empty?
                raise ArgumentError, "Object properties must have at least one property"
              end

              prop[:properties] = nested_schema[:properties]
              prop[:required] = nested_schema[:required] unless nested_schema[:required].empty?

            when "array"
              if nested_schema[:properties].empty?
                raise ArgumentError, "Array items must be defined"
              end

              # For simplicity, use the first property definition as the items schema
              # This assumes a single item type definition in the block
              prop[:items] = nested_schema[:properties].values.first
            end
          end

          @properties[name] = prop
          @required << name.to_s if required
        end

        alias item property

        private

        def validate_property_params(name, type, enum, required)
          unless name.is_a?(Symbol)
            raise ArgumentError,
                  "Name must be a symbol, got: #{name.class}"
          end

          unless VALID_TYPES.include?(type)
            raise ArgumentError, "Invalid type '#{type}'. Valid types: #{VALID_TYPES.join(', ')}"
          end

          unless enum.nil? || enum.is_a?(Array)
            raise ArgumentError, "Enum must be nil or an array, got: #{enum.class}"
          end

          return if required.is_a?(TrueClass) || required.is_a?(FalseClass)

          raise ArgumentError, "Required must be boolean, got: #{required.class}"
        end
      end
    end
  end
end
