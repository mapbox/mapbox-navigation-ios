# frozen_string_literal: true

require 'pathname'

require 'jazzy/jazzy_markdown'
require 'jazzy/source_document'

module Jazzy
  module DocumentationGenerator
    extend Config::Mixin

    def self.source_docs
      documentation_entries.map do |file_path|
        SourceDocument.new.tap do |sd|
          sd.name = File.basename(file_path, '.md')
          sd.overview = overview Pathname(file_path)
          sd.usr = "documentation.#{sd.name}"
        end
      end
    end

    def self.overview(file_path)
      return '' unless file_path&.exist?

      file_path.read
    end

    def self.documentation_entries
      return [] unless
        config.documentation_glob_configured && config.documentation_glob

      config.documentation_glob.select { |e| File.file? e }
    end
  end
end
