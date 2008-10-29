class ProcessLock
  
  def initialize(filename)
    FileUtils.touch(@filename = filename)
  end
  
  def aquire!
    File.open(@filename, 'r+') do |f|
      lock(f, false) do
        f.truncate(f.write(Process.pid))
        return true
      end
    end
    return false
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
    File.open(@filename, 'r+'){|f|lock(f){f.read.to_i}}
  end
  
  private
  
  def lock(file, blocking = true)
    file.flock(blocking ? File::LOCK_EX : File::LOCK_EX | File::LOCK_NB)
    return yield
  ensure
    file.flock(File::LOCK_UN)
  end

end
