# frozen_string_literal: true

require "spec_helper"

RSpec.describe LiteLLM::Client do
  include_context "with configured LiteLLM"

  describe "#models" do
    it "returns a list of available models" do
      models = @client.models

      expect(models).to be_an(Array)
      expect(models).to all(be_a(String))
      expect(models).to match_array(DEFAULT_MODELS)
    end
  end
end
