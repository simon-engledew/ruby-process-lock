require File.dirname(__FILE__) + '/spec_helper'

require 'fileutils'

describe 'ProcessLock' do

  before(:all) do
    FileUtils.mkdir_p("tmp")
    FileUtils.rm Dir.glob('tmp/example*tmp')
  end

  describe "#acquire" do

    it "should acquire a lock when called without a block" do
      p = ProcessLock.new('tmp/example3.tmp')
      p.should_not be_owner
      p.acquire.should be_true
      p.should be_owner
      p.should be_alive
      p.release.should be_true
      p.should_not be_owner
      p.should_not be_alive
    end

    it "should acquire a lock when called with a block and then release it" do
      p = ProcessLock.new('tmp/example4.tmp')
      p.should_not be_owner
      did_something = false
      p.acquire do
        did_something = true
        p.should be_owner
        p.should be_alive
      end.should be_true
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

    it "should acquire a lock when called with a block containing a return and then release it" do
      p = ProcessLock.new('tmp/example5.tmp')
      p.should_not be_owner
      acquire_and_then_return_block_value(p) do
        "value returned by block"
      end.should == "value returned by block"
      p.should_not be_owner
      p.should_not be_alive
    end

    it "should not acquire a lock if some other process has the lock" do
      pid = fork do
        p2 = ProcessLock.new('tmp/example6.tmp')
        Signal.trap("HUP") { p2.release! ; exit }
        p2.acquire!
        sleep(10)
        p2.release!
      end
      sleep(1)
      p = ProcessLock.new('tmp/example6.tmp')
      p.should_not be_owner
      p.should be_alive
      p.acquire.should be_false
      p.should_not be_owner
      p.should be_alive
      p.acquire do
        did_something = true
        "Some value"
      end.should be_false
      did_something.should be_false
      p.should_not be_owner
      p.should be_alive
      Process.kill("HUP", pid)
    end

    it "should allow multiple locked sections" do
      3.times do
        p = ProcessLock.new('tmp/example7.tmp')
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

  end

  describe "#acquire!" do

    it "should call acquire and expect true" do
      p = ProcessLock.new('tmp/example1a.tmp')
      p.stub(:acquire).and_return(true)
      p.acquire!.should be_nil
    end

    it "throw an error if acquire returns false" do
      p = ProcessLock.new('tmp/example1a.tmp')
      p.stub(:acquire).and_return(false)
      expect { p.acquire ) !.should raise_error
    end
  end


  describe "#read" do

    it "should return the current PID if the lock was acquired" do
      p = ProcessLock.new('tmp/example8.tmp')
      p.acquire! do
        p.read.should == Process.pid
      end
    end

    it "should return whatever number is in the file" do
      p = ProcessLock.new('tmp/example9.tmp')
      File.open(p.filename, 'w') do |f|
        f.puts("314152653")
      end
      p.read.should == 314152653
    end

  end

  describe "#filename" do

    it "should return the filename" do
      p = ProcessLock.new('tmp/example10.tmp')
      p.filename.should ==  'tmp/example10.tmp'
    end
  end


  it "should use a string for the current PID in filename" do
    p = ProcessLock.new('tmp/example11.tmp')
    p.acquire do
      File.open(p.filename, 'r') do |f|
        contents = f.read
        contents.should == Process.pid.to_s
      end
    end
  end

end
