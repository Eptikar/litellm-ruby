# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  class UserStatus
    include LiteLLM::Utils::ToolDefinition

    define_function :get_user_status, description: "Gets the current status of a user based on their ID" do
      property :user_id, type: "string", description: "The ID of the user to check"
    end

    def get_user_status(user_id:)
      case user_id
      when "user_123"
        "active"
      when "user_456"
        "inactive"
      else
        "unknown"
      end
    end
  end

  describe "tools calling" do
    it "returns active for active user" do
      messages = [{ role: "user", content: "What is the status of user_123?" }]

      response = @client.completion(
        messages: messages,
        tools: [UserStatus.new]
      )

      expect(response).to include("active")
    end

    it "returns inactive for inactive user" do
      messages = [{ role: "user", content: "What is the status of user_456?" }]

      response = @client.completion(
        messages: messages,
        tools: [UserStatus.new]
      )

      expect(response).to include("inactive")
    end

    it "returns unknown for non-existent user" do
      messages = [{ role: "user", content: "What is the status of user_999?" }]

      response = @client.completion(
        messages: messages,
        tools: [UserStatus.new]
      )

      expect(response).to include("unknown")
    end
  end
end
