require 'docx'
require 'tempfile'
require_relative '../utils/sanitizer.rb'
require_relative '../utils/adapters.rb'

class DocxContentExtractor
  attr_reader :page_count

  WORDS_PER_PAGE = 500

  # Define custom error classes
  class ExtractionError < StandardError; end
  class FileDownloadError < ExtractionError; end
  class FileReadError < ExtractionError; end
  class DocxProcessingError < ExtractionError; end

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
    Tempfile.open(['temp', '.docx'], binmode: true) do |tempfile|
      begin
        @file.download { |chunk| tempfile.write(chunk.force_encoding("ASCII-8BIT")) }
      rescue => e
        raise FileDownloadError, "Failed to download file: #{e.message}"
      end

      begin
        doc = Docx::Document.open(tempfile.path)
      rescue => e
        raise DocxProcessingError, "Failed to process DOCX file: #{e.message}"
      end

      content = extract_and_sanitize_content(doc)
      pages = split_into_pages(content)
      @page_count = pages.size

      [pages, content]
    end
  end

  def extract_and_sanitize_content(doc)
    begin
      content = doc.paragraphs.map(&:text).join("\n")
      sanitize_page_content(content)
    rescue => e
      raise FileReadError, "Failed to read content from DOCX file: #{e.message}"
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
