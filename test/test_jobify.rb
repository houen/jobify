# frozen_string_literal: true

require "test_helper"

class ApplicationJob < ActiveJob::Base; end

class BenchmarkControlJob < ApplicationJob
  def perform
    TestBunny.benchmark_control
  end
end

# Benchmark speed? Set false to skip
BENCHMARK = ENV['BENCHMARK'].to_i.nonzero? ? ENV['BENCHMARK'].to_i : false
# Output job logs?
OUTPUT_JOB_LOGS = ENV['OUTPUT_JOB_LOGS'] == 'true'

# Silence ActiveJob unless we want to see it (output is good for debugging)
unless OUTPUT_JOB_LOGS
  ActiveJob::Base.logger = Logger.new(nil)
end

# Test class for testing jobify
class TestBunny
  include Jobify

  @@state_for_testing = []

  # Some singleton method
  def self.kiss(a, b, c:, d:, e: 3)
    @@state_for_testing << "Smooch! [#{a}, #{b}, #{c}, #{e}]"
  end

  # Some instance method
  def kiss2(a, b, c:, d:, e: 3)
    @@state_for_testing << "Mmmmuah! [#{a}, #{b}, #{c}, #{e}]"
  end

  # Some instance method with same name as singleton method
  def kiss(a, b, c:, d:, e: 3)
    @@state_for_testing << "Mmmmuah! [#{a}, #{b}, #{c}, #{e}]"
  end

  # Instance methods start by finding the record via id.
  # This method enables that w/o ActiveRecord
  def self.find(id)
    raise "Test id should be 42. Was #{id}" unless id == 42

    new
  end

  # Instance methods start by finding the record via id.
  # This method enables that w/o ActiveRecord
  def id
    42
  end

  # Control method for benchmarking perform method invocation.
  # Is called normally using BenchmarkControlJob.perform
  def self.benchmark_control
    "benchmark_control"
  end

  # Reset test state
  def self.reset_state
    @@state_for_testing = []
  end

  # Get test state
  def self.state
    @@state_for_testing
  end

  # Jobify instance method
  jobify :kiss
  # Jobify other instance method method
  jobify :kiss2
  # Jobify singleton method - 1st call jobifies instance, but 2nd call will jobify singleton method
  jobify :kiss
end

class TestJobify < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # TODO: MAke owrk w/ smae name for instance and singleton

  test "it has a version number" do
    perform_enqueued_jobs do
      refute_nil ::Jobify::VERSION
    end
  end

  test "argument safety - require keyword arg c" do
    perform_enqueued_jobs do
      assert_raises(MissingKeywordArgument) do
        TestBunny.kiss_bg :a, :b, d: 2
      end
    end
  end

  test "argument safety - require keyword arg d" do
    perform_enqueued_jobs do
      assert_raises MissingKeywordArgument do
        TestBunny.kiss_bg :a, :b, c: 1
      end
    end
  end

  test "argument safety - require enough args submitted" do
    perform_enqueued_jobs do
      assert_raises MissingArgument do
        TestBunny.kiss_bg :a, c: 1, d: 2
      end
    end
  end

  test "singleton methods work w/ default kw args" do
    perform_enqueued_jobs do
      TestBunny.kiss_bg :a, :b, c: 1, d: 2
    end
  end

  test "singleton methods work w/ kw args w/ overridden defaults" do
    perform_enqueued_jobs do
      TestBunny.kiss_bg :a, :b, c: 1, d: 2, e: 4
    end
  end

  test "instance methods work w/ default kw args" do
    perform_enqueued_jobs do
      TestBunny.new.kiss2_bg :a, :b, c: 1, d: 2
    end
  end

  test "instance methods work w/ kw args w/ overridden defaults" do
    perform_enqueued_jobs do
      TestBunny.new.kiss2_bg :a, :b, c: 1, d: 2, e: 4
    end
  end

  test "result array has expected data" do
    perform_enqueued_jobs do
      TestBunny.reset_state
      TestBunny.kiss_bg :a, :b, c: 1, d: 2
      TestBunny.kiss_bg :a, :b, c: 1, d: 2, e: 4
      TestBunny.new.kiss2_bg :a, :b, c: 1, d: 2
      TestBunny.new.kiss2_bg :a, :b, c: 1, d: 2, e: 4

      assert_equal(
        ["Mmmmuah! [a, b, 1, 3]", "Mmmmuah! [a, b, 1, 4]", "Smooch! [a, b, 1, 3]", "Smooch! [a, b, 1, 4]"],
        TestBunny.state.sort
      )
    end
  end

  test 'instance and class methods can have same name and be jobified' do
    perform_enqueued_jobs do
      TestBunny.reset_state
      assert TestBunny.new.respond_to?(:kiss_bg)

      TestBunny.kiss_bg :a, :b, c: 1, d: 2, e: 4
      TestBunny.new.kiss_bg :a, :b, c: 1, d: 2, e: 4

      assert_equal(
        ["Mmmmuah! [a, b, 1, 4]", "Smooch! [a, b, 1, 4]"],
        TestBunny.state.sort
      )
    end
  end

  if BENCHMARK
    test 'benchmark' do
      perform_enqueued_jobs do
        # Define and jobify a method BOOT_BENCHMARK_ITERATIONS times
        BENCHMARK.times do |i|
          TestBunny.send(:define_method, "boot_benchmark_#{i}") do
            "boot_benchmark_#{i}"
          end
          JobifyBenchmark.benchmark(:boot) { TestBunny.send(:jobify, "boot_benchmark_#{i}".to_sym) }
        end

        (BENCHMARK / 2).times do
          JobifyBenchmark.benchmark(:perform) { TestBunny.kiss_bg :a, :b, c: 1, d: 2, e: 4 }
          JobifyBenchmark.benchmark(:perform) { TestBunny.new.kiss_bg :a, :b, c: 1, d: 2, e: 4 }
        end

        BENCHMARK.times do |i|
          JobifyBenchmark.benchmark(:perform_control) { BenchmarkControlJob.perform_later }
        end

        puts ''
        JobifyBenchmark.print
        puts ''
      end
    end
  end

end
