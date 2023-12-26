require 'dotenv'
require 'ruby/openai'
require_relative './mistral_rb.rb'
require_relative './content_extractors/content_extractor_factory.rb'
require_relative './content_splitters/basic_sentence_splitter.rb'
require_relative './embedding_engines/mistral_embeddings.rb'
require_relative './vector_stores/pinecone.rb'

Dotenv.load()

class Responder
  def initialize(vector_store:, llm:, file:, embedding_creator:)
    @vector_store = vector_store
    @llm = llm
    @file = file
    @extractor = ContentExtractorFactory.for(@file)
    @pages, @content = @extractor.call
    @embedding_creator = embedding_creator
    @embeddings = @embedding_creator.call(@pages)
    @namespace = @vector_store.store(@embeddings, @content)
  end

  def text_to_embedding(question)
    @embedding_creator.call(question, false)
  end

  def call(question, top_k=10)
    embedding = text_to_embedding(question)

    similarity_service = SimilarityService.new(question, @pages)

    results = similarity_service.most_similar_sentences(top_k)

    context = if @namespace
                @index.query(
                  vector: embedding,
                  namespace: @namespace,
                  top_k: top_k,
                  include_values: false,
                  include_metadata: true
                )
              end

    merged_text = "#{results} #{context}"

    prompt = "You are a helpful assistant. Answer this question: #{question}, using these information from the document the user uploaded: #{merged_text} in 60 words. Reply in the language of the question."

    response = @llm.create_chat_completion(
      model: "mistral-tiny",
      messages: [{role: "user", content: prompt}]
    )

    return response.choices.first.message.content
  end
end

vector_store = PineconeService.new(index_name: 'discute')
llm = MistralAPI.new(api_key: ENV["MISTRAL_API_KEY"])
file = "https://www.ycombinator.com/deal"
embedding_creator = MistralEmbeddingCreator.new

responder = Responder.new(
  vector_store: vector_store,
  llm: llm,
  file: file,
  embedding_creator: embedding_creator
)

puts responder.call("How much does YC invest per startup ?")
