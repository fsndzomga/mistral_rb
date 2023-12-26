require 'dotenv'
require_relative '../mistral_rb.rb'
require_relative '../content_splitters/basic_sentence_splitter.rb'

Dotenv.load()

class MistralEmbeddingCreator
  def initialize(api_key = nil, chunker = BasicTextChunker.new, model = "mistral-embed")
    @chunker = chunker
    @model = model
    @api_key = api_key || ENV['MISTRAL_API_KEY']

    if @api_key
      @llm = MistralAPI.new(api_key: @api_key)
    else
      Rails.logger.error "MISTRAL AI API key not provided. Set the MISTRAL_API_KEY in the ENV variables or pass it as an argument."
    end
  end

  def call(text, pages_mode=true)

    if pages_mode
      vectors = []
      return [] unless @llm  # Return empty if the API client isn't set up

      # Divide the text into chunks for each page
      text.each_with_index do |page_content, page_index|
        chunks = @chunker.split_into_chunks(page_content)

        # Create embeddings for each chunk
        chunks.each_with_index do |chunk, index|
          response = @llm.create_embeddings(
            model: @model,
            input: [chunk]
          )

          # Extract the embeddings from the response
          embedding = response.data.first.embedding

          # Create vector data for the chunk and keep page numbers for reference
          vector_data = {
            id: "vec #{index + 1}",
            values: embedding,
            metadata: {
                text: chunk,
                page: page_index + 1,
            }
          }
          # storing each chunk vector data in an array
          vectors << vector_data
        end
      end
      vectors
    else
      response = @llm.create_embeddings(
        model: @model,
        input: [text]
      )

      response.data.first.embedding
    end
  end
end
