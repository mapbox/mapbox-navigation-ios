# vim: ts=2:sw=2:sts=2:et:fdm=marker
require 'fcntl'
require 'timeout'
require 'thread'

module Open4
  VERSION = '1.3.4'
  def Open4.version() VERSION end

  def Open4.description
    'open child process with handles on pid, stdin, stdout, and stderr: manage child processes and their io handles easily.'
  end

  class Error < ::StandardError; end

  def pfork4(fun, &b)
    Open4.do_popen(b, :block) do |ps_read, _|
      ps_read.close
      begin
        fun.call
      rescue SystemExit => e
        # Make it seem to the caller that calling Kernel#exit in +fun+ kills
        # the child process normally. Kernel#exit! bypasses this rescue
        # block.
        exit! e.status
      else
        exit! 0
      end
    end
  end
  module_function :pfork4

  def popen4(*cmd, &b)
    Open4.do_popen(b, :init) do |ps_read, ps_write|
      ps_read.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      ps_write.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      exec(*cmd)
      raise 'forty-two'   # Is this really needed?
    end
  end
  alias open4 popen4
  module_function :popen4
  module_function :open4

  def popen4ext(closefds=false, *cmd, &b)
    Open4.do_popen(b, :init, closefds) do |ps_read, ps_write|
      ps_read.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      ps_write.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
      exec(*cmd)
      raise 'forty-two'   # Is this really needed?
    end
  end
  module_function :popen4ext

  def self.do_popen(b = nil, exception_propagation_at = nil, closefds=false, &cmd)
    pw, pr, pe, ps = IO.pipe, IO.pipe, IO.pipe, IO.pipe

    verbose = $VERBOSE
    begin
      $VERBOSE = nil

      cid = fork {
        if closefds
          exlist = [0, 1, 2] | [pw,pr,pe,ps].map{|p| [p.first.fileno, p.last.fileno] }.flatten
          ObjectSpace.each_object(IO){|io|
            io.close if (not io.closed?) and (not exlist.include? io.fileno) rescue nil
          }
        end

        pw.last.close
        STDIN.reopen pw.first
        pw.first.close

        pr.first.close
        STDOUT.reopen pr.last
        pr.last.close

        pe.first.close
        STDERR.reopen pe.last
        pe.last.close

        STDOUT.sync = STDERR.sync = true

        begin
          cmd.call(ps)
        rescue Exception => e
          Marshal.dump(e, ps.last)
          ps.last.flush
        ensure
          ps.last.close unless ps.last.closed?
        end

        exit!
      }
    ensure
      $VERBOSE = verbose
    end

    [ pw.first, pr.last, pe.last, ps.last ].each { |fd| fd.close }

    Open4.propagate_exception cid, ps.first if exception_propagation_at == :init

    pw.last.sync = true

    pi = [ pw.last, pr.first, pe.first ]

    begin
      return [cid, *pi] unless b

      begin
        b.call(cid, *pi)
      ensure
        pi.each { |fd| fd.close unless fd.closed? }
      end

      Open4.propagate_exception cid, ps.first if exception_propagation_at == :block

      Process.waitpid2(cid).last
    ensure
      ps.first.close unless ps.first.closed?
    end
  end

  def self.propagate_exception(cid, ps_read)
    e = Marshal.load ps_read
    raise Exception === e ? e : "unknown failure!"
  rescue EOFError
    # Child process did not raise exception.
  rescue
    # Child process raised exception; wait it in order to avoid a zombie.
    Process.waitpid2 cid
    raise
  ensure
    ps_read.close
  end

  class SpawnError < Error
    attr 'cmd'
    attr 'status'
    attr 'signals'
    def exitstatus
      @status.exitstatus
    end
    def initialize cmd, status
      @cmd, @status = cmd, status
      @signals = {} 
      if status.signaled?
        @signals['termsig'] = status.termsig
        @signals['stopsig'] = status.stopsig
      end
      sigs = @signals.map{|k,v| "#{ k }:#{ v.inspect }"}.join(' ')
      super "cmd <#{ cmd }> failed with status <#{ exitstatus.inspect }> signals <#{ sigs }>"
    end
  end

  class ThreadEnsemble
    attr 'threads'

    def initialize cid
      @cid, @threads, @argv, @done, @running = cid, [], [], Queue.new, false
      @killed = false
    end

    def add_thread *a, &b
      @running ? raise : (@argv << [a, b])
    end

#
# take down process more nicely
#
    def killall
      c = Thread.critical
      return nil if @killed
      Thread.critical = true
      (@threads - [Thread.current]).each{|t| t.kill rescue nil}
      @killed = true
    ensure
      Thread.critical = c
    end

    def run
      @running = true

      begin
        @argv.each do |a, b|
          @threads << Thread.new(*a) do |*_a|
            begin
              b[*_a]
            ensure
              killall rescue nil if $!
              @done.push Thread.current
            end
          end
        end
      rescue
        killall
        raise
      ensure
        all_done
      end

      @threads.map{|t| t.value}
    end

    def all_done
      @threads.size.times{ @done.pop }
    end
  end

  def to timeout = nil
    Timeout.timeout(timeout){ yield }
  end
  module_function :to

  def new_thread *a, &b
    cur = Thread.current
    Thread.new(*a) do |*_a|
      begin
        b[*_a]
      rescue Exception => e
        cur.raise e
      end
    end
  end
  module_function :new_thread

  def getopts opts = {}
    lambda do |*args|
      keys, default, _ = args
      catch(:opt) do
        [keys].flatten.each do |key|
          [key, key.to_s, key.to_s.intern].each do |_key|
            throw :opt, opts[_key] if opts.has_key?(_key)
          end
        end
        default
      end
    end
  end
  module_function :getopts

  def relay src, dst = nil, t = nil
    send_dst =
      if dst.respond_to?(:call)
        lambda{|buf| dst.call(buf)}
      elsif dst.respond_to?(:<<)
        lambda{|buf| dst << buf }
      else
        lambda{|buf| buf }
      end

    unless src.nil?
      if src.respond_to? :gets
        while buf = to(t){ src.gets }
          send_dst[buf]
        end

      elsif src.respond_to? :each
        q = Queue.new
        th = nil

        timer_set = lambda do |_t|
          th = new_thread{ to(_t){ q.pop } }
        end

        timer_cancel = lambda do |_t|
          th.kill if th rescue nil
        end

        timer_set[t]
        begin
          src.each do |_buf|
            timer_cancel[t]
            send_dst[_buf]
            timer_set[t]
          end
        ensure
          timer_cancel[t]
        end

      elsif src.respond_to? :read
        buf = to(t){ src.read }
        send_dst[buf]

      else
        buf = to(t){ src.to_s }
        send_dst[buf]
      end
    end
  end
  module_function :relay

  def spawn arg, *argv 
    argv.unshift(arg)
    opts = ((argv.size > 1 and Hash === argv.last) ? argv.pop : {})
    argv.flatten!
    cmd = argv.join(' ')


    getopt = getopts opts

    ignore_exit_failure = getopt[ 'ignore_exit_failure', getopt['quiet', false] ]
    ignore_exec_failure = getopt[ 'ignore_exec_failure', !getopt['raise', true] ]
    exitstatus = getopt[ %w( exitstatus exit_status status ) ]
    stdin = getopt[ %w( stdin in i 0 ) << 0 ]
    stdout = getopt[ %w( stdout out o 1 ) << 1 ]
    stderr = getopt[ %w( stderr err e 2 ) << 2 ]
    pid = getopt[ 'pid' ]
    timeout = getopt[ %w( timeout spawn_timeout ) ]
    stdin_timeout = getopt[ %w( stdin_timeout ) ]
    stdout_timeout = getopt[ %w( stdout_timeout io_timeout ) ]
    stderr_timeout = getopt[ %w( stderr_timeout ) ]
    status = getopt[ %w( status ) ]
    cwd = getopt[ %w( cwd dir ) ]
    closefds = getopt[ %w( close_fds ) ]

    exitstatus =
      case exitstatus
        when TrueClass, FalseClass
          ignore_exit_failure = true if exitstatus
          [0]
        else
          [*(exitstatus || 0)].map{|i| Integer i}
      end

    stdin ||= '' if stdin_timeout
    stdout ||= '' if stdout_timeout
    stderr ||= '' if stderr_timeout

    started = false

    status =
      begin
        chdir(cwd) do
          Timeout::timeout(timeout) do
            popen4ext(closefds, *argv) do |c, i, o, e|
              started = true

              %w( replace pid= << push update ).each do |msg|
                break(pid.send(msg, c)) if pid.respond_to? msg 
              end

              te = ThreadEnsemble.new c

              te.add_thread(i, stdin) do |_i, _stdin|
                relay _stdin, _i, stdin_timeout
                _i.close rescue nil
              end

              te.add_thread(o, stdout) do |_o, _stdout|
                relay _o, _stdout, stdout_timeout
              end

              te.add_thread(e, stderr) do |_o, _stderr| # HACK: I think this is a bug
                relay e, _stderr, stderr_timeout
              end

              te.run
            end
          end
        end
      rescue
        raise unless(not started and ignore_exec_failure)
      end

    raise SpawnError.new(cmd, status) unless
      (ignore_exit_failure or (status.nil? and ignore_exec_failure) or exitstatus.include?(status.exitstatus))

    status
  end
  module_function :spawn

  def chdir cwd, &block
    return(block.call Dir.pwd) unless cwd
    Dir.chdir cwd, &block
  end
  module_function :chdir

  def background arg, *argv 
    require 'thread'
    q = Queue.new
    opts = { 'pid' => q, :pid => q }
    case argv.last
      when Hash
        argv.last.update opts
      else
        argv.push opts
    end
    thread = Thread.new(arg, argv){|_arg, _argv| spawn _arg, *_argv}
    sc = class << thread; self; end
    sc.module_eval {
      define_method(:pid){ @pid ||= q.pop }
      define_method(:spawn_status){ @spawn_status ||= value }
      define_method(:exitstatus){ @exitstatus ||= spawn_status.exitstatus }
    }
    thread
  end
  alias bg background
  module_function :background
  module_function :bg

  def maim pid, opts = {}
    getopt = getopts opts
    sigs = getopt[ 'signals', %w(SIGTERM SIGQUIT SIGKILL) ]
    suspend = getopt[ 'suspend', 4 ]
    pid = Integer pid
    existed = false
    sigs.each do |sig|
      begin
        Process.kill sig, pid
        existed = true 
      rescue Errno::ESRCH
        return(existed ? nil : true)
      end
      return true unless alive? pid
      sleep suspend
      return true unless alive? pid
    end
    return(not alive?(pid)) 
  end
  module_function :maim

  def alive pid
    pid = Integer pid
    begin
      Process.kill 0, pid
      true
    rescue Errno::ESRCH
      false
    end
  end
  alias alive? alive
  module_function :alive
  module_function :'alive?'
end

def open4(*cmd, &b) cmd.size == 0 ? Open4 : Open4::popen4(*cmd, &b) end
