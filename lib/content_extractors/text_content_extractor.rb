require 'tempfile'
require_relative '../utils/sanitizer.rb'
require_relative '../utils/adapters.rb'

class TxtContentExtractor
  attr_reader :page_count

  WORDS_PER_PAGE = 500

  # Define custom error classes
  class ExtractionError < StandardError; end
  class FileDownloadError < ExtractionError; end
  class FileReadError < ExtractionError; end

  def initialize(file)
    @file = file
  end

  def call
    extract_content
  rescue StandardError => e
    raise ExtractionError, "Content extraction failed: #{e.message}"
  end

  private

  def extract_content
    Tempfile.open(['temp', '.txt'], binmode: true) do |tempfile|
      begin
        @file.download { |chunk| tempfile.write(chunk.force_encoding("UTF-8")) }
      rescue => e
        raise FileDownloadError, "Failed to download file: #{e.message}"
      end

      begin
        content = File.read(tempfile.path)
      rescue => e
        raise FileReadError, "Failed to read file: #{e.message}"
      end

      sanitized_content = sanitize_page_content(content)
      pages = split_into_pages(sanitized_content)
      @page_count = pages.size

      [pages, content]
    end
  end

  def split_into_pages(content)
    words = content.split(/\s+/)
    pages = []
    words.each_slice(WORDS_PER_PAGE) do |page_words|
      pages << page_words.join(' ')
    end
    pages
  end

  # Sanitize the content
  def sanitize_page_content(content)
    sanitized_text = Sanitizer.remove_excessive_newlines(content)
    sanitized_text = Sanitizer.remove_excessive_spaces(sanitized_text)
    sanitized_text = Sanitizer.remove_bullet_points(sanitized_text)
    # Add additional sanitization methods as required
    sanitized_text
  end
end
