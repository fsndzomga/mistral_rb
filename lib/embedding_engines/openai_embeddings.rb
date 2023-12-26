require 'dotenv'
require 'ruby/openai'
require_relative '../content_splitters/basic_sentence_splitter.rb'

Dotenv.load()

class OpenaiEmbeddingCreator
  def initialize(api_key = nil, chunker = BasicTextChunker.new, model = "text-embedding-ada-002")
    @chunker = chunker
    @model = model
    @api_key = api_key || ENV['OPENAI_API_KEY']

    if @api_key
      @llm = OpenAI::Client.new(access_token: @api_key)
    else
      Rails.logger.error "OpenAI API key not provided. Set the OPENAI_API_KEY in the ENV variables or pass it as an argument."
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
          response = @llm.embeddings(
            parameters: {
              model: @model,
              input: chunk
            }
          )

          # Extract the embeddings from the response
          embedding = response['data'][0]['embedding']

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
      response = @llm.embeddings(
        parameters: {
          model: @model,
          input: chunk
        }
      )
      # Extract the embeddings from the response
      response['data'][0]['embedding']
    end
  end
end
