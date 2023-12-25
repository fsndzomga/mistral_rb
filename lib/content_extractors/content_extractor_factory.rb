require "mime/types"
require "httparty"

class ContentExtractorFactory
  def self.for(file)
    type = determine_file_type(file)

    case type
    when :pdf
      PdfContentExtractor.new(file)
    when :docx
      DocxContentExtractor.new(file)
    when :txt
      TxtContentExtractor.new(file)
    when :html
      HtmlContentExtractor.new(file)
    else
      raise "Unsupported file type: #{type}"
    end
  end

  private

  def self.determine_file_type(file)
    if file_is_url?(file)
      content_type = fetch_url_content_type_with_httparty(file)
      return :html if content_type.include?('text/html')
    else
      content_type = file.content_type
    end

    case content_type
    when 'application/pdf'
      :pdf
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      :docx
    when 'text/plain'
      :txt
    else
      :unknown
    end
  end

  def self.file_is_url?(file)
    file.respond_to?(:to_str) && file.to_str =~ /\A#{URI::regexp(['http', 'https'])}\z/
  end

  def self.fetch_url_content_type_with_httparty(url)
    response = HTTParty.head(url)
    response.headers['content-type']
  rescue HTTParty::Error
    :unknown
  end
end
