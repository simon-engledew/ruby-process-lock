require "process_lock/version"

class ProcessLock

  attr_reader :filename

  class AlreadyLocked < StandardError
  end
  
  def initialize(filename)
    @filename = filename
    FileUtils.touch(@filename)
  end
  
  def acquire!
    unless acquire
      raise AlreadyLocked.new("Unable to acquire lock")
    end
  end

  def acquire
    acquired = false
    open_and_lock do |f|
      acquired = owner? || ! alive?
      if acquired
        f.truncate(f.write(Process.pid))
      end
    end
    if block_given?
      if acquired
        begin
          Proc.new.call
        ensure
          release
        end
      end
    else
      acquired
    end
  end

  def release!
    unless release
      raise AlreadyLocked.new("Unable to release lock (probably did not own it)")
    end
  end

  def release
    acquired = false
    open_and_lock do |f|
      acquired = owner?
      if acquired
        f.truncate(f.write(0))
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

  def open_and_lock
    old_locked_file = @locked_file
    if @locked_file
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
