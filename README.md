# Jobify

Run any method as a background job automatically. Works with both instance and class methods.

## Why?
I think we as Rails developers are not using background processing as much as we could / should.

I believe this is largely because of 3 things:

- The extra work required to create a new MyTinyJob class
- The added complexity from moving code away from its natural and cohesive location in the project and into app/jobs
- The extra work required to _maintain_ a tiny MyTinyJob class

In summary, the activation energy to use background jobs is too high.

This gem lowers the activation energy to practically nothing: 

```
jobify :do_stuff
```

`do_stuff` is now jobified and can be queued with `perform_do_stuff_later(whatever_method_args)`

## Usage
```
class SomeClass
  include Jobify
  
  def self.do_stuff(arg1, kw_arg:) 
    puts "...stuff which would be handy to do async..."
  end
  jobify :do_stuff
end

SomeClass.perform_do_stuff_later(42, kw_arg: 'flum')

[ActiveJob] Enqueued SomeClass::JobifySingletonMethod_do_stuff_Job (Job ID: 46f95723-dfd6-4dbc-bbff-cb06baabf5b5) to Async(default) with arguments: 42, {:kw_arg=>"flum"}
[ActiveJob] [SomeClass::JobifySingletonMethod_do_stuff_Job] [46f95723-dfd6-4dbc-bbff-cb06baabf5b5] Performing SomeClass::JobifySingletonMethod_do_stuff_Job (Job ID: 46f95723-dfd6-4dbc-bbff-cb06baabf5b5) from Async(default) enqueued at 2022-10-25T12:00:04Z with arguments: 42, {:kw_arg=>"flum"}
irb(main):011:0> ...stuff which would be handy to do async...
[ActiveJob] [SomeClass::JobifySingletonMethod_do_stuff_Job] [46f95723-dfd6-4dbc-bbff-cb06baabf5b5] Performed SomeClass::JobifySingletonMethod_do_stuff_Job (Job ID: 46f95723-dfd6-4dbc-bbff-cb06baabf5b5) from Async(default) in 22.16ms
```

### Features
- Jobifies class methods
- Jobifies instance methods
- Verifies correct arguments are given when enqueing a job 
- Small overhead added: 0.06 ms boot and 0.1ms on perform 
- Override perform_xyz_later method with whatever name you prefer (eg. `jobify :do_stuff, name: :do_stuff_async`) 

### Notes on instance methods
Instance methods are supported by adding a special keyword argument to `JobifySingletonMethod_xyz_Job#perform`. 
The first thing `#perform_xyz_later` does is get the id of the instance via `#id`.
This id is passed to `#perform_later` of the job as an extra argument. The perform method uses this to find the record, 
and then run the instance method on the record.

In short: If your model classes do not inherit from ApplicationRecord and do not supply `#id` and `.find(id)` methods, 
you will need to add them to use `jobify` on instance methods.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jobify

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jobify

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
