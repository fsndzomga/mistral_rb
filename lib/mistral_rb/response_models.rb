class CompletionResponse
  attr_reader :id, :object, :created, :model, :choices, :usage

  def initialize(response_hash)
    @id = response_hash["id"]
    @object = response_hash["object"]
    @created = response_hash["created"]
    @model = response_hash["model"]
    @choices = response_hash["choices"].map { |choice| Choice.new(choice) }
    @usage = response_hash["usage"]
  end
end

class Choice
  attr_reader :index, :message

  def initialize(choice_hash)
    @index = choice_hash["index"]
    @message = Message.new(choice_hash["message"])
  end
end

class Message
  attr_reader :role, :content

  def initialize(message_hash)
    @role = message_hash["role"]
    @content = message_hash["content"]
  end
end

class EmbeddingResponse
  attr_reader :id, :object, :data, :model, :usage

  def initialize(response_hash)
    @id = response_hash["id"]
    @object = response_hash["object"]
    @data = response_hash["data"].map { |embedding_data| Embedding.new(embedding_data) }
    @model = response_hash["model"]
    @usage = response_hash["usage"]
  end
end

class Embedding
  attr_reader :object, :embedding, :index

  def initialize(embedding_hash)
    @object = embedding_hash["object"]
    @embedding = embedding_hash["embedding"]
    @index = embedding_hash["index"]
  end
end

class ModelListResponse
  attr_reader :object, :data

  def initialize(response_hash)
    @object = response_hash["object"]
    @data = response_hash["data"].map { |model_data| Model.new(model_data) }
  end
end

class Model
  attr_reader :id, :object, :created, :owned_by, :permissions

  def initialize(model_hash)
    @id = model_hash["id"]
    @object = model_hash["object"]
    @created = model_hash["created"]
    @owned_by = model_hash["owned_by"]
    @permissions = model_hash["permission"] # This could be further parsed into Permission objects if detailed parsing is required
  end
end
