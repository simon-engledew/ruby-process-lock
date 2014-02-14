require 'process_lock'
require 'timeout'

module TimeoutMatcher
  extend RSpec::Matchers::DSL

  matcher :time_out do |value|
    match do |block|
      begin
        Timeout.timeout(value) do
          block.call
          false
        end
      rescue TimeoutError
        true
      end
    end
  end
end

RSpec.configure do |c|
  c.include TimeoutMatcher
  c.before(:all) do
    FileUtils.touch(@path = 'tmp/spec')
    File.truncate(@path, 0)
  end
end