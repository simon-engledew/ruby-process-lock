require File.dirname(__FILE__) + '/spec_helper'

require 'fileutils'

describe 'ProcessLock' do

  before(:all) do
    FileUtils.mkdir_p('tmp/pids')
    FileUtils.rm_f Dir.glob('tmp/pids/example*.tmp')
  end

  describe '#acquire' do

    it 'should acquire a lock when called without a block' do
      p = ProcessLock.new('tmp/pids/example1.txt')
      p.should_not be_owner
      p.acquire.should be_true
      p.should be_owner
      p.should be_alive
      p.release.should be_true
      p.should_not be_owner
      p.should_not be_alive
    end

    it 'should acquire a lock when called with a block and then release it' do
      p = ProcessLock.new('tmp/pids/example2.txt')
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
      p = ProcessLock.new('tmp/pids/example3.txt')
      p.should_not be_owner
      acquire_and_then_return_block_value(p) do
        'value returned by block'
      end.should == 'value returned by block'
      p.should_not be_owner
      p.should_not be_alive
    end

    it 'should not acquire a lock if some other process has the lock' do
      fn = 'tmp/pids/example4.txt'
      system('bash spec/other_process.sh "%s" 100' % fn)
      p = ProcessLock.new(fn)
      200.times do |i|
        break if p.read > 0
        sleep(0.5)
        puts "waited #{i+1} times" if i > 2
      end
      pid = p.read
      puts "+ps -fp %d" % pid
      system "ps -fp %d" % pid
      # other process should have acquired the lock
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
      Process.kill(9, pid) if pid> 0
    end

    it 'should acquire a lock if an completed process has the lock' do
      fn = 'tmp/pids/example5.txt'
      system('bash spec/other_process.sh "%s" 0' % fn)
      p = ProcessLock.new(fn)
      200.times do |i|
        break if p.read > 0 && ! p.alive?
        sleep(0.5)
        puts "waited #{i+1} times" if i > 2
      end

      p = ProcessLock.new(fn)
      p.should_not be_owner
      p.should_not be_alive
      p.acquire.should be_true
      p.should be_owner
      p.should be_alive
      p.release
    end

    it 'should allow multiple sequential locked sections' do
      3.times do
        p = ProcessLock.new('tmp/pids/example6.txt')
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
      ps = 3.times.collect { |i| ProcessLock.new('tmp/pids/example7-%d.txt' % i) }
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
      p = ProcessLock.new('tmp/pids/example8.txt')
      p.stub(:acquire_without_block).and_return(true)
      p.acquire!.should be_true
    end

    it 'throw an error if acquire returns false' do
      p = ProcessLock.new('tmp/pids/example9.txt')
      p.stub(:acquire_without_block).and_return(false)
      expect { p.acquire! }.to raise_error(ProcessLock::AlreadyLocked)
    end

    it 'should acquire a lock when called with a block and then release it' do
      p = ProcessLock.new('tmp/pids/example2.txt')
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
      p = ProcessLock.new('tmp/pids/example10.txt')
      p.stub(:release).and_return(true)
      p.release!.should be_true
    end

    it 'throw an error if release returns false' do
      p = ProcessLock.new('tmp/pids/example11.txt')
      p.stub(:release).and_return(false)
      expect { p.release! }.to raise_error(ProcessLock::NotLocked)
    end
  end


  describe '#read' do

    it 'should return the current PID if the lock was acquired' do
      p = ProcessLock.new('tmp/pids/example12.txt')
      p.acquire do
        p.read.should == Process.pid
        p.should be_alive
      end
      p.should_not be_alive
    end

    it 'should return whatever number is in the file' do
      p = ProcessLock.new('tmp/pids/example13.txt')
      File.open(p.filename, 'w') do |f|
        f.puts('314152653')
      end
      p.read.should == 314152653
    end

  end

  describe '#filename' do

    class Rails
      def self.root
        '.'
      end
    end

    it 'should return the path' do
      fn = 'tmp/pids/example14'
      p = ProcessLock.new(fn)
      p.filename.should == fn
    end

    it 'should return tmp/pids/exampleN.pid for a simple name if Rails.root is set' do
      fn = 'example14b'
      Rails.root.should == '.'
      p = ProcessLock.new(fn)
      p.filename.should == "./tmp/pids/%s.pid" % fn
    end

    it 'should return tmp/pids/NAME.ext for NAME.ext if Rails.root is set' do
      fn = 'example14c.ext'
      p = ProcessLock.new(fn)
      p.filename.should == "./tmp/pids/%s" % fn
    end

  end

  it 'should use a string for the current PID in filename' do
    p = ProcessLock.new('tmp/pids/example15.txt')
    p.acquire do
      File.open(p.filename, 'r') do |f|
        contents = f.read
        contents.should == Process.pid.to_s
      end
    end
  end

end
