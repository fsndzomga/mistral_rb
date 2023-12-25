require 'nokogiri'
require 'watir'
require 'webdrivers'
require_relative '../utils/sanitizer.rb'

class HtmlContentExtractor
  attr_reader :content

  class ExtractionError < StandardError; end
  class UrlDownloadError < ExtractionError; end
  class ParsingError < ExtractionError; end

  BROWSERS = [:chrome, :firefox, :safari]

  def initialize(url)
    @url = url
  end

  def call
    extract_content
  rescue StandardError => e
    raise ExtractionError, "HTML content extraction failed: #{e.message}"
  end

  private

  def extract_content
    BROWSERS.each do |browser|
      begin
        html = download_html_with_watir(browser)
        document = parse_html(html)
        text_content = document.xpath('//body').text.strip
        title = document.title

        combined_content = "#{title}\n\n#{text_content}"
        @content = sanitize_content(combined_content)
        return
      rescue UrlDownloadError => e
        next
      end
    end

    raise UrlDownloadError, "Failed to download URL with all browser drivers"
  end

  def download_html_with_watir(browser)
    browser = Watir::Browser.new(browser, headless: true)
    browser.goto(@url)
    sleep(5)  # Adjust sleep time as needed for JavaScript to render
    html_content = browser.html
    browser.quit
    html_content
  rescue => e
    raise UrlDownloadError, "Failed to download URL using #{browser.to_s.capitalize} browser: #{e.message}"
  ensure
    browser.quit if browser.exists?
  end

  def parse_html(html)
    Nokogiri::HTML(html)
  rescue => e
    raise ParsingError, "Failed to parse HTML content: #{e.message}"
  end

  def sanitize_content(content)
    sanitized_text = Sanitizer.remove_excessive_newlines(content)
    sanitized_text = Sanitizer.remove_excessive_spaces(sanitized_text)
    sanitized_text = Sanitizer.remove_bullet_points(sanitized_text)
    sanitized_text
  end
end
