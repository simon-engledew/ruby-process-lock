# ProcessLock

A simple class to acquire and check process-id file based locks on a unix filesystem.

[![Build Status](https://travis-ci.org/ianheggie/ruby-process-lock.png?branch=master)](https://travis-ci.org/ianheggie/ruby-process-lock)

## Installation

Add this line to your application's Gemfile:

    gem 'process_lock'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_lock

## Usage

Create an instance of ProcessLock with a filename as the lock.
You may have more than one lock per process.

Methods:
* acquire - Acquires a lock if it can. Returns true (or value of block if block is passed) if a lock was acquired, otherwise false.
* acquire! - Same as acquire except it throws an exception if a lock could not be obtained.
* release - Releases the lock if we are the owner. Returns true if the lock was released.
* release! - Same as release except it throws an exception if a lock was not released.
* filename - the filename passed when the instance was created
* read - the process id in the lock file, otherwise 0 (zero)

Note:
* locks don't stack - if we have already acquired the lock subsequent calls will reacquire the lock. releasing an already released lock will fail.

To acquire a lock, do some work and then release it:

    pl = ProcessLock.new('tmp/name_of_lock.pid')

    acquired = pl.acquire do
      puts "Do some work!"
    end
    puts "Unable to obtain a lock" unless acquired

    # OR

    while ! pl.acquire
      puts "Trying to acquire a lock"
      sleep(1)
    end
    puts "Do some work!"
    pl.release


Example:

irb - run first

    >> require 'process_lock'
    => true
    >> Process.pid
    => 16568
    >> p = ProcessLock.new('tmp/example.tmp')
    => #<ProcessLock:0x00000001489c10 @filename="tmp/example.tmp">
    >> p.alive?
    => false
    >> p.owner?
    => false
    >> p.read
    => 0

    >> p.acquire!
    => true

    >> p.alive?
    => true
    >> p.owner?
    => true
    >> p.read
    => 16568
    >> sleep(10)
    => 10
    >> p.release!
    => true
    >> p.alive?
    => false
    >> p.owner?
    => false
    >> p.read
    => 0

2nd irb, run after first has acquired the lock

    >> require 'process_lock'
    => true
    >> Process.pid
    => 16569
    >> q = ProcessLock.new('tmp/example.tmp')
    => #<ProcessLock:0x000000026e4090 @filename="tmp/example.tmp">
    >> q.alive?
    => true
    >> q.owner?
    => false
    >> q.read
    => 16568

    >> q.acquire!
    ProcessLock::AlreadyLocked: Unable to acquire lock
            from /home/ianh/Projects/Github/ruby-process-lock/lib/process_lock.rb:28:in `acquire!'
            from (irb):7
            from /home/ianh/.rbenv/versions/1.9.3-p484/bin/irb:12:in `<main>'

    >> q.alive?
    => true
    >> q.owner?
    => false
    >> q.read
    => 16568
    >>

example.tmp will contain the pid of the running process

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License and contributions

* Based on work Copyright (c) 2008 Simon Engledew, released under the MIT license.
* Subsequent work by Ian Heggie: packaged into a gem, added tests and acquire method, fixed acquire so it didn't overwrite locks by other processes.
* See git log for other contributers

