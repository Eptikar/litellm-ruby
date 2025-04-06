# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  describe "embedding generation" do
    it "generates embeddings for text input" do
      embedding = @client.embedding(input: "Hello, world!")
      
      expect(embedding).to be_an(Array)
      expect(embedding).not_to be_empty
      expect(embedding.first).to be_a(Float)
      expect(embedding.size).to eq(1536)
    end

    it "generates embeddings with custom dimensions" do
      embedding = @client.embedding(input: "Hello, world!", dimensions: 256)
      
      expect(embedding).to be_an(Array)
      expect(embedding).not_to be_empty
      expect(embedding.first).to be_a(Float)
      expect(embedding.size).to eq(256)
    end
  end
end 