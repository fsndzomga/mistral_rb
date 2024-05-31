# frozen_string_literal: true

require_relative "mistral_rb/version"
require "httparty"
require "json"
require_relative "mistral_rb/response_models"
require 'dotenv'

Dotenv.load()

class MistralAPI
  include HTTParty

  def initialize(api_key: ENV["MISTRAL_API_KEY"], base_uri: "https://api.mistral.ai/v1")
    raise 'API key not found. Please set the MISTRAL_API_KEY environment variable.' if api_key.nil? || api_key.empty?
    @headers = {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
    self.class.base_uri base_uri
  end

  def create_chat_completion(model:, messages:, temperature: 0.7, top_p: 1, max_tokens: nil, stream: false, safe_prompt: false, random_seed: nil, tools: nil, tool_choice: nil, response_format: nil)
    body = {
      model: model,
      messages: messages,
      temperature: temperature,
      top_p: top_p,
      max_tokens: max_tokens,
      stream: stream,
      safe_prompt: safe_prompt,
      random_seed: random_seed,
      tools: tools,
      tool_choice: tool_choice,
      response_format: response_format
    }.compact.to_json

    if stream
      # Use on_data callback for streaming
      self.class.post("/chat/completions", body: body, headers: @headers, stream_body: true) do |fragment, _, _|
        processed_chunk = handle_stream_chunk(fragment)
        yield(processed_chunk) if block_given? && processed_chunk
      end
    else
      # Handle non-streaming response
      response = self.class.post("/chat/completions", body: body, headers: @headers)
      parsed_response = handle_response(response)
      MistralModels::CompletionResponse.new(parsed_response)
    end
  end

  def create_fim_completion(prompt:, suffix:, model:, temperature: 0.7, top_p: 1, max_tokens: nil, min_tokens: 0, stream: false, random_seed: nil, stop: [])
    body = {
      prompt: prompt,
      suffix: suffix,
      model: model,
      temperature: temperature,
      top_p: top_p,
      max_tokens: max_tokens,
      min_tokens: min_tokens,
      stream: stream,
      random_seed: random_seed,
      stop: stop
    }.compact.to_json

    if stream
      self.class.post("/fim/completions", body: body, headers: @headers, stream_body: true) do |fragment, _, _|
        processed_chunk = handle_stream_chunk(fragment)
        yield(processed_chunk) if block_given? && processed_chunk
      end
    else
      response = self.class.post("/fim/completions", body: body, headers: @headers)
      parsed_response = handle_response(response)
      MistralModels::CompletionResponse.new(parsed_response)
    end
  end

  def create_embeddings(model:, input:, encoding_format: "float")
    body = {
      model: model,
      input: input,
      encoding_format: encoding_format
    }.to_json

    response = self.class.post("/embeddings", body: body, headers: @headers)
    parsed_response = handle_response(response)
    MistralModels::EmbeddingResponse.new(parsed_response)
  end

  def list_available_models
    response = self.class.get("/models", headers: @headers)
    parsed_response = handle_response(response)
    MistralModels::ModelListResponse.new(parsed_response)
  end

  private

  def handle_response(response)
    if response.code.between?(200, 299)
      JSON.parse(response.body)
    else
      raise "API Error: #{response.code} - #{response.body}"
    end
  end

  def handle_stream_chunk(chunk)
    # Skip processing if the chunk indicates the end of the stream.
    return nil if chunk.strip == "data: [DONE]"

    if chunk.strip.start_with?("data:")
      data_content = chunk.split("data:").last.strip
      begin
        # Only parse the JSON content if it's not the end-of-stream indicator
        json_content = JSON.parse(data_content)
        MistralModels::StreamedCompletionResponse.new(json_content)
      rescue JSON::ParserError => e
        puts "Error parsing JSON: #{e.message}"
      end
    end
  end
end
