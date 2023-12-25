require 'pdf-reader'
require 'tempfile'
require_relative '../utils/sanitizer.rb'
require_relative '../utils/adapters.rb'

class PdfContentExtractor
  attr_reader :page_count

  # Define custom error classes
  class ExtractionError < StandardError; end
  class UnreadableContentError < ExtractionError; end
  class EmptyContentError < ExtractionError; end

  def initialize(file)
    @file = file
    @page_count = 0
  end

  def call
    extract_content
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    # Handle known PDF::Reader errors
    raise UnreadableContentError, "PDF could not be read: #{e.message}"
  rescue StandardError => e
    # Handle any other unforeseen errors
    raise ExtractionError, "Content extraction failed: #{e.message}"
  end

  private

  def extract_content
    Tempfile.open(['extracted_content', '.pdf'], binmode: true) do |tempfile|
      begin
        @file.download { |chunk| tempfile.write(chunk.force_encoding("ASCII-8BIT")) }
        tempfile.close # Close the tempfile to flush and save data before reading

        reader = PDF::Reader.new(tempfile.path)
        @page_count = reader.page_count # Store the page count

        pages = reader.pages.map do |page|
          # Encode the extracted text to UTF-8, replacing invalid characters
          page_text = page.text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

          # Sanitize the page text
          sanitize_page_content(page_text)
        end

        raise EmptyContentError, 'The PDF content is empty or unreadable.' if pages.all? { |page| page.nil? || page.strip.empty? }

        pages
      ensure
        tempfile.unlink # Delete the tempfile
      end
    end
  end

  # Sanitize the page content
  def sanitize_page_content(page_text)
    sanitized_text = Sanitizer.remove_excessive_newlines(page_text)
    sanitized_text = Sanitizer.remove_excessive_spaces(sanitized_text)
    sanitized_text = Sanitizer.remove_bullet_points(sanitized_text)
    # Add additional sanitization methods as required

    sanitized_text
  end
end
