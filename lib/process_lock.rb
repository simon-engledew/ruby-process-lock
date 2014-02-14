class File
  # open a file with exclusive write permissions, blocking between processes
  # until the lock is released
  def self.open_exclusive(path, mode='r+')
    File.open(path, mode) do |handle|
      begin
        handle.flock(File::LOCK_EX)
        return yield(handle)
      ensure
        handle.flock(File::LOCK_UN)
      end
    end
  end
end

module Process
  # check to see if a process is alive using a null signal
  def self.alive?(pid)
    return pid > 0 && Process.kill(0, pid) > 0
  rescue Errno::ESRCH
    return false
  end
end

class PidFile
  def initialize(filename)
    FileUtils.touch(@filename = filename)
  end

  # attempt to atomically write your PID into a file when many processes are starting
  # simultaneously
  def acquire!
    File.open_exclusive(@filename) do |handle|
      pid = handle.read.to_i
      return true if pid == Process.pid
      if not Process.alive?(pid)
        handle.truncate(0)
        handle.write(Process.pid)
        return true
      end
    end
    return false
  end

  # truncate the pidfile and allow another processes to write theirs
  def release!
    File.open_exclusive(@filename) do |handle|
      pid = handle.read.to_i
      if pid == 0 || pid == Process.pid
        handle.truncate(0)
        return true
      end
    end
    return false
  end
end
