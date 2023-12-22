# frozen_string_literal: true

require_relative "mistral_rb/version"
require "httparty"
require "json"
require_relative "mistral_rb/response_models"

class MistralAPI
  include HTTParty
  base_uri "https://api.mistral.ai/v1"

  def initialize(api_key)
    @headers = {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end

  def create_chat_completion(model, messages, temperature = 0.7, top_p = 1, max_tokens = nil, stream = false, safe_mode = false, random_seed = nil)
    body = {
      model: model,
      messages: messages,
      temperature: temperature,
      top_p: top_p,
      max_tokens: max_tokens,
      stream: stream,
      safe_mode: safe_mode,
      random_seed: random_seed
    }.compact.to_json  # compact to remove nil values

    response = self.class.post("/chat/completions", body: body, headers: @headers)
    parsed_response = handle_response(response)
    CompletionResponse.new(parsed_response)
  end

  def create_embeddings(model, input, encoding_format = "float")
    body = {
      model: model,
      input: input,
      encoding_format: encoding_format
    }.to_json

    response = self.class.post("/embeddings", body: body, headers: @headers)
    parsed_response = handle_response(response)
    EmbeddingResponse.new(parsed_response)
  end

  def list_available_models
    response = self.class.get("/models", headers: @headers)
    parsed_response = handle_response(response)
    ModelListResponse.new(parsed_response)
  end

  private

  def handle_response(response)
    if response.code.between?(200, 299)
      JSON.parse(response.body)
    else
      raise "API Error: #{response.code} - #{response.body}"
    end
  end
end
