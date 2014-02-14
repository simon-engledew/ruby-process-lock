require File.dirname(__FILE__) + '/spec_helper'

require 'fileutils'

describe 'ProcessLock' do

  before(:all) do
    FileUtils.mkdir_p('tmp')
    FileUtils.rm_f Dir.glob('tmp/example*.tmp')
  end

  describe '#acquire' do

    it 'should acquire a lock when called without a block' do
      p = ProcessLock.new('tmp/example1.txt')
      p.should_not be_owner
      p.acquire.should be_true
      p.should be_owner
      p.should be_alive
      p.release.should be_true
      p.should_not be_owner
      p.should_not be_alive
    end

    it 'should acquire a lock when called with a block and then release it' do
      p = ProcessLock.new('tmp/example2.txt')
      p.should_not be_owner
      did_something = false
      p.acquire do
        did_something = true
        p.should be_owner
        p.should be_alive
        'value from block'
      end.should  == 'value from block'
      did_something.should be_true
      p.should_not be_owner
      p.should_not be_alive
    end

    def acquire_and_then_return_block_value(pl)
      pl.acquire do
        @acquired_lock = true
        pl.should be_owner
        pl.should be_alive
        return yield
      end
    end

    it 'should acquire a lock when called with a block containing a return and then release it' do
      p = ProcessLock.new('tmp/example3.txt')
      p.should_not be_owner
      acquire_and_then_return_block_value(p) do
        'value returned by block'
      end.should == 'value returned by block'
      p.should_not be_owner
      p.should_not be_alive
    end

    it 'should not acquire a lock if some other process has the lock' do
      fn = 'tmp/example4.txt'
      pid = fork do
        p2 = ProcessLock.new(fn)
        Signal.trap('HUP') { p2.release!; exit }
        p2.acquire!
        sleep(1000)
        p2.release!
      end
      p = ProcessLock.new(fn)
      100.times do |i|
        break if p.read == pid
        sleep(0.2)
        puts "waited #{i+1} times" if i > 2
      end
      # other process should have acquired the lock
      p.read.should == pid
      p.should_not be_owner
      p.should be_alive
      p.acquire.should be_false
      p.should_not be_owner
      p.should be_alive
      # also try block
      did_something = false
      p.acquire do
        did_something = true
        'Some value'
      end.should be_false
      did_something.should be_false
      p.should_not be_owner
      p.should be_alive
      Process.kill('HUP', pid)
    end

    it 'should acquire a lock if an completed process has the lock' do
      fn = 'tmp/example5.txt'
      pid = fork do
        p2 = ProcessLock.new(fn)
        p2.acquire!
        exit
      end
      Process.waitpid(pid)
      p = ProcessLock.new(fn)
      my_pid = Process.pid
      x = p.read
      o = p.owner?
      a = p.alive?
      p.should_not be_owner
      p.should_not be_alive
      p.acquire.should be_true
      x = p.read
      o = p.owner?
      a = p.alive?
      p.should be_owner
      p.should be_alive
      p.release
    end

    it 'should allow multiple sequential locked sections' do
      3.times do
        p = ProcessLock.new('tmp/example6.txt')
        p.should_not be_owner
        did_something = false
        p.acquire do
          did_something = true
          p.should be_owner
          p.should be_alive
        end.should be_true
        p.should_not be_owner
        p.should_not be_alive
        did_something.should be_true
      end
    end

    it 'should allow multiple parallel but differently named locked sections' do
      ps = 3.times.collect { |i| ProcessLock.new('tmp/example7-%d.txt' % i) }
      did_something = 0
      ps.each do |p|
        p.should_not be_owner
        p.acquire
        p.should be_owner
        p.should be_alive
      end
      ps.each do |p|
        p.should be_owner
        p.should be_alive
        p.release
        p.should_not be_owner
        p.should_not be_alive
      end
    end

  end

  describe '#acquire!' do

    it 'should call acquire and expect true' do
      p = ProcessLock.new('tmp/example8.txt')
      p.stub(:acquire_without_block).and_return(true)
      p.acquire!.should be_true
    end

    it 'throw an error if acquire returns false' do
      p = ProcessLock.new('tmp/example9.txt')
      p.stub(:acquire_without_block).and_return(false)
      expect { p.acquire! }.to raise_error(ProcessLock::AlreadyLocked)
    end

    it 'should acquire a lock when called with a block and then release it' do
      p = ProcessLock.new('tmp/example2.txt')
      p.should_not be_owner
      did_something = false
      p.acquire! do
        did_something = true
        p.should be_owner
        p.should be_alive
        'some value'
      end.should == 'some value'
      did_something.should be_true
      p.should_not be_owner
      p.should_not be_alive
    end

  end

  describe '#release!' do

    it 'should call release and expect true' do
      p = ProcessLock.new('tmp/example10.txt')
      p.stub(:release).and_return(true)
      p.release!.should be_true
    end

    it 'throw an error if release returns false' do
      p = ProcessLock.new('tmp/example11.txt')
      p.stub(:release).and_return(false)
      expect { p.release! }.to raise_error(ProcessLock::NotLocked)
    end
  end


  describe '#read' do

    it 'should return the current PID if the lock was acquired' do
      p = ProcessLock.new('tmp/example12.txt')
      p.acquire do
        p.read.should == Process.pid
        p.should be_alive
      end
      p.should_not be_alive
    end

    it 'should return whatever number is in the file' do
      p = ProcessLock.new('tmp/example13.txt')
      File.open(p.filename, 'w') do |f|
        f.puts('314152653')
      end
      p.read.should == 314152653
    end

  end

  describe '#filename' do

    it 'should return the filename' do
      fn = 'tmp/example14.txt'
      p = ProcessLock.new(fn)
      p.filename.should == fn
    end
  end

  it 'should use a string for the current PID in filename' do
    p = ProcessLock.new('tmp/example15.txt')
    p.acquire do
      File.open(p.filename, 'r') do |f|
        contents = f.read
        contents.should == Process.pid.to_s
      end
    end
  end

end
