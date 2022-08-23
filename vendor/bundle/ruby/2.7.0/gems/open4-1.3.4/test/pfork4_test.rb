require 'test_case'

module Open4

class PFork4Test < TestCase
  def test_fun_successful_return
    fun = lambda { 'lucky me' }
    cid, _ = pfork4 fun
    assert_equal 0, wait_status(cid)
  end

  def test_fun_force_exit
    exit_code = 43
    fun = lambda { exit! exit_code }
    cid, _ = pfork4 fun
    assert_equal exit_code, wait_status(cid)
  end

  def test_fun_normal_exit
    exit_code = 43
    fun = lambda { exit exit_code }
    cid, _ = pfork4 fun
    assert_equal exit_code, wait_status(cid)
  end

  def test_fun_does_not_propagate_exception_without_block
    fun = lambda { raise MyError }
    cid, _ = pfork4 fun
    refute_equal 0, wait_status(cid)
  end

  def test_fun_propagate_exception_with_block
    fun = lambda { raise MyError }
    assert_raises(MyError) { pfork4(fun) {} }
  end

  def test_fun_propagate_exception_with_block_avoids_zombie_child_process
    fun = lambda { raise MyError }
    assert_raises(MyError) { pfork4(fun) {} }
    assert_empty Process.waitall
  end

  def test_call_block_upon_exception
    fun = lambda { raise MyError }
    block_called = false
    assert_raises(MyError) { pfork4(fun) { block_called = true } }
    assert_equal true, block_called
  end

  def test_passes_child_pid_to_block
    fun = lambda { $stdout.write Process.pid }
    cid_in_block = nil
    cid_in_fun = nil
    pfork4(fun) do |cid, _, stdout, _|
      cid_in_block = cid
      cid_in_fun = stdout.read.to_i
    end
    assert_equal cid_in_fun, cid_in_block
  end

  def test_io_pipes_without_block
    via_msg = 'foo'
    err_msg = 'bar'
    fun = lambda do
      $stdout.write $stdin.read
      $stderr.write err_msg
    end
    out_actual, err_actual = nil, nil
    cid, stdin, stdout, stderr = pfork4 fun
    stdin.write via_msg
    stdin.close
    out_actual = stdout.read
    err_actual = stderr.read
    assert_equal via_msg, out_actual
    assert_equal err_msg, err_actual
    assert_equal 0, wait_status(cid)
  end

  def test_io_pipes_with_block
    via_msg = 'foo'
    err_msg = 'bar'
    fun = lambda do
      $stdout.write $stdin.read
      $stderr.write err_msg
    end
    out_actual, err_actual = nil, nil
    status = pfork4(fun) do |_, stdin, stdout, stderr|
      stdin.write via_msg
      stdin.close
      out_actual = stdout.read
      err_actual = stderr.read
    end
    assert_equal via_msg, out_actual
    assert_equal err_msg, err_actual
    assert_equal 0, status.exitstatus
  end

  def test_exec_in_fun
    via_msg = 'foo'
    fun = lambda { exec %{ruby -e "print '#{via_msg}'"} }
    out_actual = nil
    status = pfork4(fun) do |_, stdin, stdout, _|
      stdin.close
      out_actual = stdout.read
    end
    assert_equal via_msg, out_actual
    assert_equal 0, status.exitstatus
  end

  def test_io_pipes_and_then_exception_propagation_with_block
    via_msg = 'foo'
    err_msg = 'bar'
    fun = lambda do
      $stdout.write $stdin.read
      $stderr.write err_msg
      raise MyError
    end
    out_actual, err_actual = nil, nil
    assert_raises(MyError) do
      pfork4(fun) do |_, stdin, stdout, stderr|
        stdin.write via_msg
        stdin.close
        out_actual = stdout.read
        err_actual = stderr.read
      end
    end
    assert_equal via_msg, out_actual
    assert_equal err_msg, err_actual
  end

  def test_blocked_on_io_read_and_exception_propagation_with_block
    fun = lambda do
      $stdin.read
      raise MyError
    end
    out_actual, err_actual = nil, nil
    assert_raises(MyError) do
      pfork4(fun) do |_, stdin, stdout, stderr|
        stdin.write 'foo'
        stdin.close
        out_actual = stdout.read
        err_actual = stderr.read
      end
    end
    assert_equal '', out_actual
    assert_equal '', err_actual
  end
end

end
