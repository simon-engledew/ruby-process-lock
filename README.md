A set of simple multiprocess concurrency examples originally designed to allow many worker processes to self organise and identify a leader process.

Example:

```
IRB 1>>
pid = PidFile.new('example.tmp')
pid.acquire!
=> true
File.read('example.tmp')
=> "2435"

IRB 2>>
pid = PidFile.new('example.tmp')
pid.acquire!
=> false
File.read('example.tmp')
=> "2435"
```

If you are looking for the process_lock gem, go here: https://github.com/ianheggie/ruby-process-lock/

Copyright (c) 2008-2014 Simon Engledew, released under the MIT license
