require 'active_job'
require 'jobify'

class ApplicationJob < ActiveJob::Base; end

class BenchmarkControlJob < ApplicationJob
  def perform
    TestBunny.benchmark_control
  end
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

  def self.kiss?
    @@state_for_testing << "Kiss?"
  end

  def self.kiss!
    @@state_for_testing << "Kiss!"
  end

  def self.class_methods_are_jobified_first
    true
  end

  def class_methods_are_jobified_first
    true
  end

  jobify :class_methods_are_jobified_first

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
  jobify :kiss?
  jobify :kiss!
end
