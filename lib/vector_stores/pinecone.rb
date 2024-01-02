require 'pinecone'
require 'digest'
require 'dotenv'

Dotenv.load()

class PineconeService
  attr_reader :index
  def initialize(pinecone_key: ENV['PINECONE_API_KEY'], pinecone_env: ENV['PINECONE_ENV'], index_name:)
    raise 'API key not found. Please set the PINECONE_API_KEY environment variable.' if pinecone_key.nil? || pinecone_key.empty?
    raise 'ENV not found. Please set the PINECONE_ENV environment variable.' if pinecone_env.nil? || pinecone_env.empty?
    @pinecone_key = pinecone_key
    @pinecone_env = pinecone_env
    @index_name = index_name


    Pinecone.configure do |config|
      config.api_key  = @pinecone_key
      config.environment = @pinecone_env
    end

    if @pinecone_key && @pinecone_env
      @pinecone = Pinecone::Client.new
    else
      Rails.logger.error "Set the PINECONE_API_KEY and PINECONE_ENV in the ENV variables"
    end
    @index = @pinecone.index(@index_name)
  end

  def compute_hash(text)
    Digest::SHA256.hexdigest(text)[0...44]
  end

  def store(embeddings, text)
    namespace = compute_hash(text)

    upsert_with_retry(@index, namespace, embeddings)

    namespace
  end

  private

  def upsert_with_retry(index, namespace, embeddings, max_retries = 5, retry_delay = 10)
    retries = 0
    response = nil

    loop do
      response = index.upsert(
        namespace: namespace,
        vectors: embeddings
      )

      break if response["code"] != 9 || retries >= max_retries

      puts "Encountered error. Retrying in #{retry_delay} seconds... (Attempt #{retries + 1} of #{max_retries})"
      sleep(retry_delay)
      retries += 1
    end

    response
  end
end
