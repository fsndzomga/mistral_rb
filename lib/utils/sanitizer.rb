module Sanitizer
  # Remove sequences of more than two newline characters
  def self.remove_excessive_newlines(text)
    text.gsub(/(\n\s*){3,}/, "\n\n")
  end

  # Remove sequences of more than two spaces and replace with one space
  def self.remove_excessive_spaces(text)
    text.gsub(/ {3,}/, ' ')
  end

  # Remove bullet point characters
  def self.remove_bullet_points(text)
    text.gsub("•", "")
  end
end
