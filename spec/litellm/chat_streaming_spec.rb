# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  describe "streaming responses" do
    it "supports streaming responses" do
      chunks = []

      @client.completion(messages: [{ role: "user", content: "Count from 1 to 3" }], model: "gpt-3.5-turbo", stream: true) do |chunk|
        chunks << chunk
      end

      expect(chunks).not_to be_empty
      expect(chunks).to all(be_a(String))
      expect(chunks.join).to include("1")
      expect(chunks.join).to include("2")
      expect(chunks.join).to include("3")
    end
  end
end
