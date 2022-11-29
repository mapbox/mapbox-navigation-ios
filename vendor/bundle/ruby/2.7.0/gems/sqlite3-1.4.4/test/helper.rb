require 'sqlite3'
require 'minitest/autorun'

if ENV['GITHUB_ACTIONS'] == 'true' || ENV['CI']
  $VERBOSE = nil
  puts "\nSQLite3 Version: #{SQLite3::SQLITE_VERSION}   $VERBOSE = nil", ""
else
  puts "\nSQLite3 Version: #{SQLite3::SQLITE_VERSION}", ""
end

unless RUBY_VERSION >= "1.9"
  require 'iconv'
end

module SQLite3
  class TestCase < Minitest::Test
    alias :assert_not_equal :refute_equal
    alias :assert_not_nil   :refute_nil
    alias :assert_raise     :assert_raises

    def assert_nothing_raised
      yield
    end
  end
end
