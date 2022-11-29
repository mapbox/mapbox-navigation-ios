# coding: utf-8

require 'minitest/autorun'
require 'open4'
require 'rbconfig'

module Open4
  class TestCase < MiniTest::Unit::TestCase
    include Open4

    # Custom exception class for tests so we don't shadow possible
    # programming errors.
    class MyError < RuntimeError; end

    def on_mri?
      ::RbConfig::CONFIG['ruby_install_name'] == 'ruby'
    end

    def wait_status(cid)
      Process.waitpid2(cid).last.exitstatus
    end
  end
end
