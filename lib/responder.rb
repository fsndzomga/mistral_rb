require 'dotenv'
require 'ruby/openai'
require_relative './mistral_rb.rb'
require_relative './content_extractors/content_extractor_factory.rb'
require_relative './content_splitters/basic_sentence_splitter.rb'
require_relative './embedding_engines/mistral_embeddings.rb'
require_relative './vector_stores/pinecone.rb'
require_relative './utils/similarity_service.rb'
require_relative './utils/adapters.rb'

Dotenv.load()

class Responder
  def initialize(vector_store:, llm: MistralAPI.new, file:, embedding_creator: MistralEmbeddingCreator.new)
    @vector_store = vector_store
    @llm = llm
    @file = file
    @embedding_creator = embedding_creator
  end

  def call(question, top_k=10)
    embedding = text_to_embedding(question)
    results = process_similarity(question, top_k)
    context = fetch_context(embedding, top_k)
    merged_text = merge_texts(results, context)
    prompt = construct_prompt(question, merged_text)
    generate_response(prompt)
  end

  private

  def extract_content
    @extractor ||= ContentExtractorFactory.for(@file)

    # Check if either @pages or @content is uninitialized
    if @pages.nil? || @content.nil?
      extracted_pages, extracted_content = @extractor.call
      @pages ||= extracted_pages
      @content ||= extracted_content
    end
  end

  def store_embeddings
    @embeddings ||= @embedding_creator.call(@pages)
    @namespace ||= @vector_store.store(@embeddings, @content)
  end

  def text_to_embedding(question)
    @embedding_creator.call(question, false)
  end

  # This method processes the similarity between the question and the content
  def process_similarity(question, top_k)
    extract_content # Ensure content is extracted
    similarity_service = SimilarityService.new(question, @pages)
    similarity_service.most_similar_sentences(top_k)
  end

  # Fetches context from the vector store based on the embedding
  def fetch_context(embedding, top_k)
    store_embeddings # Ensure embeddings are stored
    if @namespace
      @vector_store.index.query(
        vector: embedding,
        namespace: @namespace,
        top_k: top_k,
        include_values: false,
        include_metadata: true
      )
    else
      nil
    end
  end

  # Merges the results from similarity processing with the context
  def merge_texts(results, context)
    [results, context].compact.join(' ')
  end

  def construct_prompt(question, merged_text)
    "You are a helpful assistant. Answer this question: #{question}, using these information from the document the user uploaded: #{merged_text} in 60 words. Reply in the language of the question."
  end

  def generate_response(prompt)
    response = @llm.create_chat_completion(
      model: "mistral-tiny",
      messages: [{role: "user", content: prompt}]
    )
    response.choices.first.message.content
  end
end
