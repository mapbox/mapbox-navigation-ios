module Liferaft
  def self.version_string_create(major, minor, patch, build = 0)
    "#{major}#{(minor + 'A'.ord).chr}#{patch * 1000 + build}"
  end

  class Version
    include Comparable

    attr_reader :major, :minor, :patch, :build

    def initialize(version_string)
      components = version_string.downcase.split(/[a-z]/)
      character = version_string.downcase.gsub(/[^a-z]/, '')

      if character.length > 2 || character.empty?
        @major = @minor = @patch = @build = 0
        return
      end

      @major = components[0].to_i
      @minor = character.ord - 'a'.ord
      @patch = components[1].to_i / 1000
      @build = (character.length == 2 ? character[-1].ord : 0) + components[1].to_i % 1000
    end

    def to_s
      "#{@major}.#{@minor}.#{@patch} Build #{@build}"
    end

    def <=>(other)
      %i(major minor patch build).lazy.map do |component|
        send(component) <=> other.send(component)
      end.find(&:nonzero?) || 0
    end
  end
end
