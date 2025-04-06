# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  describe "image generation" do
    it "generates an image URL from a prompt" do
      url = @client.image_generation(prompt: "A beautiful sunset over a calm ocean")
      
      expect(url).to be_a(String)
      expect(url).to start_with("https://oaidalleapiprodscus.blob.core.windows.net/private/")
      expect(url).to include("img-")
      expect(url).to include(".png")
      expect(url).to include("&rsct=image/png")
    end
  end
end 