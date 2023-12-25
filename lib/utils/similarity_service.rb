
class SimilarityService
  FRENCH_STOP_WORDS = %w(
    je tu il nous vous ils elle me te se le la les et ou mais
    que quand donc or ni car
  ).freeze

  ENGLISH_STOP_WORDS = %w(
    i you he we they she me him us them and or but that when so nor for
  ).freeze

  STOP_WORDS = (FRENCH_STOP_WORDS + ENGLISH_STOP_WORDS).freeze

  def initialize(input_question, document_chunks)
    @input_question = input_question
    @document_chunks = document_chunks
  end

  def jaccard_similarity(str1, str2)
    set1 = str1.downcase.split(" ").reject { |word| STOP_WORDS.include?(word) }.to_set
    set2 = str2.downcase.split(" ").reject { |word| STOP_WORDS.include?(word) }.to_set
    intersection = set1 & set2
    union = set1 | set2
    intersection.size.to_f / union.size
  end

  def most_similar_sentences(top_k)
    sentence_delimiters = /[\.\?!:]/
    all_sentences = @document_chunks.flat_map { |chunk| chunk.split(sentence_delimiters).map(&:strip) }

    similarities = all_sentences.map do |sentence|
      [sentence, jaccard_similarity(@input_question, sentence)]
    end

    # Sort by similarity and take the top_k
    top_sentences = similarities.sort_by { |_, similarity| -similarity }.take(top_k).map(&:first)

    top_sentences.join(' ')
  end
end
