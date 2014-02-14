# ProcessLock

A simple class to aquire and check process-id file based locks on a unix filesystem.

## Installation

Add this line to your application's Gemfile:

    gem 'process_lock'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_lock

## Usage

To acquire a lock, do some work and then release it:

```ruby
pl = ProcessLock.new('service_name')

pl.acquire do
  puts "Do some work!"
end

# OR

if pl.acquire
  begin
    puts "Do some work"
  ensure
    pl.release!
  end
end
```

To forceably acquire a lock (eg to designame a master process), use:

```ruby
pl = ProcessLock.new('service_name')
pl.acquire!
```

To forceably release a lock (even if you do not own it), use:

```ruby
pl = ProcessLock.new('service_name')
pl.release!
```

Example:

```irb
IRB 1>>
p = ProcessLock.new('example.tmp')
p.owner?
=> false
p.aquire!
=> true
p.owner?
=> true
```

```irb
IRB 2>>
q = ProcessLock.new('example.tmp')
p.owner?
=> false
p.aquire!
=> false
p.owner?
=> false
p.alive?
=> true
```

example.tmp will contain the pid of the running process

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

* Copyright (c) 2008 Simon Engledew, released under the MIT license.
* Packaged into a gem, tests and acquire method added by Ian Heggie.
* See git log for other contributers

