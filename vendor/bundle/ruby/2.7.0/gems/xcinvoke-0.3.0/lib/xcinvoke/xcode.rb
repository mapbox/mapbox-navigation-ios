require 'liferaft'
require 'open3'

module XCInvoke
  class Xcode
    extend Enumerable

    attr_reader :developer_dir

    def initialize(path)
      @developer_dir = Pathname(path)
    end

    def self.selected
      dir, = Open3.capture2('xcode-select', '-p', err: '/dev/null')
      new(dir.strip)
    end

    def self.each(&blk)
      xcodes, = Open3.capture2('mdfind',
                               "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'",
                               err: '/dev/null')
      xcodes = xcodes.split("\n").map(&:strip)
      xcodes = xcodes.map do |xc|
        xc = Pathname(xc) + 'Contents/Developer'
        new(xc)
      end
      xcodes.each(&blk)
    end

    def self.all
      to_a
    end

    def self.find_swift_version(swift_version)
      swift_version = Gem::Version.create(swift_version)
      select { |xc| xc.swift_version == swift_version }.sort.last
    end

    def swift_version
      info = swift_info
      Gem::Version.new(info.first) if info
    end

    def build_number
      info = xcodebuild_info
      info[1] if info
    end

    def version
      build = build_number
      Liferaft::Version.new(build) if build
    end

    def <=>(other)
      version <=> other.version
    end

    def xcrun(cmd, env: {}, err: false)
      env = env.merge(as_env)

      # xcrun self-lookup is a workaround for issues caused by having
      # multiple very old versions of Xcode installed
      # (see https://github.com/segiddins/xcinvoke/issues/3)
      @xcrun_path ||= Open3.capture3('xcrun', '-f', 'xcrun').first.strip

      # Env-based lookup is necessary for Xcode ≥8
      @xcrun_path = 'xcrun' if @xcrun_path == ''

      cmd = [@xcrun_path] + cmd
      case err
      when :merge
        oe, = Open3.capture2e(env, *cmd)
        oe
      else
        o, e, = Open3.capture3(env, *cmd)
        err ? [o, e] : o
      end
    end

    def as_env
      {
        'DEVELOPER_DIR' => developer_dir.to_path,
        'DYLD_FRAMEWORK_PATH' =>
          unshift_path(ENV['DYLD_FRAMEWORK_PATH'], dyld_framework_path),
        'DYLD_LIBRARY_PATH' =>
          unshift_path(ENV['DYLD_LIBRARY_PATH'], dyld_library_path),
      }
    end

    def dyld_framework_path
      developer_dir + 'Toolchains/XcodeDefault.xctoolchain/usr/lib'
    end

    def dyld_library_path
      developer_dir + 'Toolchains/XcodeDefault.xctoolchain/usr/lib'
    end

    private

    def xcodebuild_info
      xcodebuild_info_regex = /\AXcode (.*?)\s*Build version (.*?)\s*\Z/i
      return unless xcrun(%w(xcodebuild -version)) =~ xcodebuild_info_regex
      [Regexp.last_match(1), Regexp.last_match(2)]
    end

    def swift_info
      swift_info_regex = /Swift version ([\d\.]+) \(swift(?:lang)?-([\d\.]+)/i
      return unless xcrun(%w(swift --version)) =~ swift_info_regex
      [Regexp.last_match(1), Regexp.last_match(2)]
    end

    def unshift_path(paths, path)
      paths = (paths || '').split(File::PATH_SEPARATOR)
      paths.unshift(path.to_s)
      paths.join(File::PATH_SEPARATOR)
    end
  end
end
