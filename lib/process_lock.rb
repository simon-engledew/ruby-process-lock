require 'process_lock/version'
require 'fileutils'

class ProcessLock

  attr_reader :filename

  class AlreadyLocked < StandardError
  end

  class NotLocked < StandardError
  end

  def initialize(filename)
    @filename = filename
    FileUtils.touch(@filename)
  end
  
  def acquire!
    result = acquired = acquire_without_block
    if acquired and block_given?
      begin
        result = yield
      ensure
        release
      end
    end
    raise(AlreadyLocked.new('Unable to acquire lock')) unless acquired
    result
  end

  def acquire
    result = acquire_without_block
    if result and block_given?
      begin
        result = yield
      ensure
        release
      end
    end
    result
  end

  def release!
    unless release
      raise NotLocked.new('Unable to release lock (probably did not own it)')
    end
    true
  end

  def release
    acquired = false
    open_and_lock do |f|
      acquired = owner?
      if acquired
        f.truncate(f.write(''))
      end
    end
    acquired
  end
  
  def alive?
    pid = read
    return pid > 0 ? Process.kill(0, pid) > 0 : false
  rescue
    return false
  end
  
  def owner?
    pid = read
    pid and pid > 0 and pid == Process.pid
  end
  
  def read
    open_and_lock{|f| f.read.to_i}
  end
  
  private

  def acquire_without_block
    result = false
    open_and_lock do |f|
      result = owner? || ! alive?
      if result
        f.rewind
        f.truncate(f.write(Process.pid))
      end
    end
    result
  end

  def open_and_lock
    old_locked_file = @locked_file
    if @locked_file
      @locked_file.rewind
      return yield @locked_file
    else
      File.open(@filename, 'r+') do |f|
        lock(f) do
          @locked_file = f
          return yield f
        end
      end
    end
  ensure
    @locked_file = old_locked_file
  end

  def lock(file, blocking = true)
    file.flock(blocking ? File::LOCK_EX : File::LOCK_EX | File::LOCK_NB)
    return yield
  ensure
    file.flock(File::LOCK_UN)
  end

end
