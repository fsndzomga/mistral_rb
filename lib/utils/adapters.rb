class LocalFileAdapter
  # This adapter will wrap a local file path and provide a download method that yields the file's contents
  def initialize(file_path)
    @file_path = file_path
  end

  def download
    File.open(@file_path, 'rb') do |file|
      yield file.read
    end
  end
end
