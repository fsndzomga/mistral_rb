# frozen_string_literal: true

require_relative "lib/mistral_rb/version"

Gem::Specification.new do |spec|
  spec.name = "mistral_rb"
  spec.version = MistralRb::VERSION
  spec.authors = ["Franck Stephane Ndzomga"]
  spec.email = ["ndzomgafs@gmail.com"]

  spec.summary = "A simple wrapper for the Mistral API"
  spec.description = "This gem provides an easy-to-use interface for the Mistral AI API."
  spec.homepage = "https://github.com/fsndzomga/mistral_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fsndzomga/mistral_rb"
  spec.metadata["changelog_uri"] = "https://github.com/fsndzomga/mistral_rb/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Specify runtime and development dependencies in gemspec
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_runtime_dependency "httparty", "~> 0.18"
  spec.add_runtime_dependency "mime-types"
  spec.add_runtime_dependency "pdf-reader"
  spec.add_runtime_dependency "pinecone"
  spec.add_runtime_dependency "docx"
  spec.add_runtime_dependency "dotenv-rails"
  # spec.add_runtime_dependency "csv"
  # spec.add_runtime_dependency "daru"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency 'selenium-webdriver', '~> 4.5'
  spec.add_runtime_dependency 'webdrivers', '~> 5.3'
  spec.add_runtime_dependency 'watir'
  spec.add_runtime_dependency 'ruby-openai'
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
