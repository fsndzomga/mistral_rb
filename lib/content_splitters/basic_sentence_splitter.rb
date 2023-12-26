require 'ruby/openai'

class BasicTextChunker
  def initialize(token_limit=390)
    @token_limit = token_limit
  end

  def split_into_chunks(text)
    sentences = text.split(/[.!?]\s+/)
    chunks = []
    current_chunk = ""
    current_token_count = 0

    sentences.each do |sentence|
      sentence_token_count = OpenAI.rough_token_count(sentence)

      while sentence_token_count > @token_limit
        tokens_to_take = @token_limit - current_token_count
        partial = sentence.split(/\s+/).first(tokens_to_take).join(" ")
        current_chunk += partial + " "
        sentence = sentence[partial.length..].strip
        current_token_count += tokens_to_take
        sentence_token_count -= tokens_to_take

        if current_token_count == @token_limit
          chunks << current_chunk.strip
          current_chunk = ""
          current_token_count = 0
        end
      end

      if current_token_count + sentence_token_count <= @token_limit
        current_chunk += sentence + " "
        current_token_count += sentence_token_count
      else
        chunks << current_chunk.strip
        current_chunk = sentence + " "
        current_token_count = sentence_token_count
      end
    end

    chunks << current_chunk.strip unless current_chunk.empty?
    chunks
  end
end
