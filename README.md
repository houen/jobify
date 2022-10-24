# Jobify

Run any method as a background job automatically. Works with instance and singleton methods.

**Short example:**
```
# Class code
jobify :method_name

# To run method as background (bg) job
method_name_bg
```

**Longer example:**
```
class SomeClass
  include Jobify
  
  def self.my_method(arg1, kw_arg:) 
    puts "...stuff which would be handy to do async..."
  end
  jobify :my_method
end

SomeClass.my_method_bg(42, kw_arg: 'flum')

[ActiveJob] [SomeClass::JobifySingletonMethod_my_method_Job] [1e55320f-482c-442a-b5d2-eff4102cfeda] Performing SomeClass::JobifySingletonMethod_my_method_Job (Job ID: 1e55320f-482c-442a-b5d2-eff4102cfeda) from Async(default) enqueued at 2022-10-24T07:51:43Z with arguments: 42, {:kw_arg=>"flum"}
irb(main):011:0> ...stuff which would be handy to do async...
[ActiveJob] [SomeClass::JobifySingletonMethod_my_method_Job] [1e55320f-482c-442a-b5d2-eff4102cfeda] Performed SomeClass::JobifySingletonMethod_my_method_Job (Job ID: 1e55320f-482c-442a-b5d2-eff4102cfeda) from Async(default) in 24.96ms
```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jobify

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jobify

## Usage

TODO: Write usage instructions here

### Benchmarks
Benchmarks from running on a Macbook Pro:

**Booting Rails:**

Jobify adds ~ 0.06 ms avg overhead per call. So if you used `rolify :something` 100 times in your code, you would add ~ 6 milliseconds overhead to boot time.

**Running jobs**

Rolify adds ~ 0.1 ms overhead to running a job. Performing via jobify takes ~ 0.23 ms versus ~ 0.13 ms for normal ActiveJob execution.
For all but the most massively-scheduled-all-the-time jobs, this should be fine.

```
Benchmark boot: 0.058 ms on avg of 100000 iterations
Benchmark perform: 0.228 ms on avg of 100000 iterations
Benchmark perform_control: 0.128 ms on avg of 100000 iterations
```

Generate benchmarks by running `BENCHMARK=100_000 rake test` where env BENCHMARK is the number of iterations to run

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/jobify.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
