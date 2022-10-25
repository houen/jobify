# Jobify

Run any method as a background job with `perform_my_method_later`. Works with both instance and class methods.

## Why?

I think we as Rails developers are not using background processing as much as we could / should.

I believe this is largely because of 3 things:

- The extra work required to create a new MyTinyJob class
- The added complexity from moving code away from its natural and cohesive location in the project and into app/jobs
- The extra work required to _maintain_ a tiny MyTinyJob class

In short, the activation energy to use background jobs is too high.

Jobify lowers the activation energy to `jobify :do_stuff` to generate an activejob job class, and calling `perform_do_stuff_later`

## Usage

```
class SomeClass
  include Jobify
  
  def self.do_stuff(arg1, kw_arg:) 
    puts "...#{arg1} #{kw_arg}'s which would be handy to do async..."
  end
  jobify :do_stuff
end

SomeClass.perform_do_stuff_later(42, kw_arg: 'flum')
```

Output:

```
[ActiveJob] Enqueued SomeClass::JobifyClassMethod_do_stuff_Job (Job ID: 8fc2ca69-cb31-4f73-a908-e98acb8a2832) to Async(default) with arguments: 42, {:kw_arg=>"flum"}
[ActiveJob] [SomeClass::JobifyClassMethod_do_stuff_Job] [8fc2ca69-cb31-4f73-a908-e98acb8a2832] Performing SomeClass::JobifyClassMethod_do_stuff_Job (Job ID: 8fc2ca69-cb31-4f73-a908-e98acb8a2832) from Async(default) enqueued at 2022-10-25T19:11:46Z with arguments: 42, {:kw_arg=>"flum"}
=>
#<SomeClass::JobifyClassMethod_do_stuff_Job:0x00007fee638d9cb8
 @arguments=[42, {:kw_arg=>"flum"}],
 @exception_executions={},
 @executions=0,
 @job_id="8fc2ca69-cb31-4f73-a908-e98acb8a2832",
 @priority=nil,
 @provider_job_id="8dc0614f-a229-4648-9308-4e6add9f666c",
 @queue_name="default",
 @successfully_enqueued=true,
 @timezone=nil>
...42 flum's which would be handy to do async...
[ActiveJob] [SomeClass::JobifyClassMethod_do_stuff_Job] [8fc2ca69-cb31-4f73-a908-e98acb8a2832] Performed SomeClass::JobifyClassMethod_do_stuff_Job (Job ID: 8fc2ca69-cb31-4f73-a908-e98acb8a2832) from Async(default) in 4.57ms
```

### Features

- Jobifies class methods
- Jobifies instance methods
- Verifies correct arguments are given when enqueing a job
- Small overhead added: 0.06 ms boot and 0.1ms on perform
- Override perform_xyz_later method with whatever name you prefer (eg. `jobify :do_stuff, name: :do_stuff_async`)

### Instance methods

Instance methods work out of the box if your class inherits from `ApplicationRecord` or `ActiveRecord::Base`

If your class does not inherit from these it must supply `#id` and `.find(id)` methods to use `jobify` on
instance methods.

### How it works
Calling `jobify :my_method` will declare two things:
- A new activejob job class as subclass of the class where it is called. This class `#perform` method will call the original method using `public_send`. 
- A `perform_my_method_later` method, which will perform the job later. 
  - `perform_my_method_later` will raise unless given the same arguments as `my_method`.

#### Instance methods
Jobifying instance methods work by adding a special id keyword argument to `JobifyInstanceMethod_xyz_Job#perform`:

- When called, `#perform_xyz_later` gets the id of the instance via `instance#id`.
- The id is passed to the jobs `#perform` method as extra argument (`:__jobify__record_id`).
- `#perform` method uses this to find the record and then run the instance method on the record.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jobify

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jobify

### Overhead

Benchmarks from running on a 2020 i7 Macbook Pro:

(Generate benchmarks by running `BENCHMARK=10_000 rake test` where env BENCHMARK is the number of iterations to run)
```
Benchmark boot: 0.058 ms on avg of 100000 iterations
Benchmark perform: 0.228 ms on avg of 100000 iterations
Benchmark perform_control: 0.128 ms on avg of 100000 iterations
```

**Boot overhead:**

Jobify adds ~ 0.06 ms avg overhead per call.
So if you used `jobify :something` 100 times in your code, you would add ~ 6 ms overhead to boot time.

**Run job overhead**

Jobify adds ~ 0.1 ms overhead to running a job. Performing via jobify takes ~ 0.23 ms versus ~ 0.13 ms for normal
ActiveJob execution.
For all but the most massively-scheduled-all-the-time jobs, this should be fine.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/houen/jobify.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
