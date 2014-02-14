require File.dirname(__FILE__) + '/spec_helper'

describe File do
  it 'can acquire a multiprocess critical region' do
    expect { |b| File.open_exclusive(@path, &b) }.to yield_control
  end

  it 'cannot acquire from a forked process' do
    pid = nil

    File.open_exclusive(@path) do
      expect {
        pid = Process.fork do
          expect { |b| File.open_exclusive(@path, &b) }.to yield_control
        end
        Process.wait(pid)
      }.to time_out(0.5)
    end

    expect(pid).not_to be_nil
    Process.wait(pid)
  end
end

describe Process do
  it 'can successfully determine if another process is alive or dead' do
    pid = nil

    File.open_exclusive(@path) do
      expect {
        pid = Process.fork do
          expect { |b| File.open_exclusive(@path, &b) }.to yield_control
        end
        expect(Process.alive?(pid)).to be_true
        Process.wait(pid)
      }.to time_out(0.5)
    end

    expect(pid).not_to be_nil
    Process.wait(pid)

    expect(Process.alive?(pid)).to be_false
  end
end

describe PidFile do
  it 'can successfully acquire a pidfile' do
    pid = PidFile.new(@path)
    expect(pid.acquire!).to be_true
    expect(pid.release!).to be_true
  end

  it 'cannot acquire a pidfile if it is being used by another process' do
    pid = PidFile.new(@path)
    expect(pid.acquire!).to be_true

    Process.wait(Process.fork do
      fork_pid = PidFile.new(@path)
      expect(fork_pid.acquire!).to be_false
      expect(fork_pid.release!).to be_false
    end)

    expect(pid.release!).to be_true
  end
end