# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  describe "basic chat functionality" do
    it "can have a basic conversation" do
      messages = [{ role: "user", content: "What's 2 + 2?" }]
      response = @client.completion(messages: messages, model: "gpt-3.5-turbo")

      expect(response).to be_a(String)
      expect(response).to include("4")
    end

    it "can handle multi-turn conversations" do
      messages = [
        { role: "user", content: "Who was Ruby's creator?" },
        { role: "assistant", content: "Yukihiro Matsumoto (Matz)" },
        { role: "user", content: "What year did he create Ruby?" }
      ]
      response = @client.completion(messages: messages, model: "gpt-3.5-turbo")

      expect(response).to be_a(String)
      expect(response).to include("199")
    end

    it "successfully uses the system prompt" do
      messages = [{ role: "user", content: "Tell me about the weather." }]
      system_message = 'You must respond like a pirate and include the phrase "Arrr matey!" in your response.'

      response = @client.completion(
        messages: messages,
        model: "gpt-3.5-turbo",
        system_message: system_message
      )

      expect(response).to be_a(String)
      expect(response).to include("Arrr matey!")
    end
  end
end
