# frozen_string_literal: true

require "test_helper"
require "test_bunny"

class TestJobify < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "it has a version number" do
    perform_enqueued_jobs do
      refute_nil ::Jobify::VERSION
    end
  end

  test "argument safety - require keyword arg c" do
    perform_enqueued_jobs do
      assert_raises(MissingKeywordArgument) do
        TestBunny.perform_kiss_later :a, :b, d: 2
      end
    end
  end

  test "argument safety - require keyword arg d" do
    perform_enqueued_jobs do
      assert_raises MissingKeywordArgument do
        TestBunny.perform_kiss_later :a, :b, c: 1
      end
    end
  end

  test "argument safety - require enough args submitted" do
    perform_enqueued_jobs do
      assert_raises MissingArgument do
        TestBunny.perform_kiss_later :a, c: 1, d: 2
      end
    end
  end

  test "singleton methods work w/ default kw args" do
    perform_enqueued_jobs do
      TestBunny.perform_kiss_later :a, :b, c: 1, d: 2
    end
  end

  test "singleton methods work w/ kw args w/ overridden defaults" do
    perform_enqueued_jobs do
      TestBunny.perform_kiss_later :a, :b, c: 1, d: 2, e: 4
    end
  end

  test "instance methods work w/ default kw args" do
    perform_enqueued_jobs do
      TestBunny.new.perform_kiss2_later :a, :b, c: 1, d: 2
    end
  end

  test "instance methods work w/ kw args w/ overridden defaults" do
    perform_enqueued_jobs do
      TestBunny.new.perform_kiss2_later :a, :b, c: 1, d: 2, e: 4
    end
  end

  test "result array has expected data" do
    perform_enqueued_jobs do
      TestBunny.reset_state
      TestBunny.perform_kiss_later :a, :b, c: 1, d: 2
      TestBunny.perform_kiss_later :a, :b, c: 1, d: 2, e: 4
      TestBunny.new.perform_kiss2_later :a, :b, c: 1, d: 2
      TestBunny.new.perform_kiss2_later :a, :b, c: 1, d: 2, e: 4

      assert_equal(
        ["Mmmmuah! [a, b, 1, 3]", "Mmmmuah! [a, b, 1, 4]", "Smooch! [a, b, 1, 3]", "Smooch! [a, b, 1, 4]"],
        TestBunny.state.sort
      )
    end
  end

  test "instance and class methods can have same name and be jobified" do
    perform_enqueued_jobs do
      TestBunny.reset_state
      assert TestBunny.new.respond_to?(:perform_kiss_later)

      TestBunny.perform_kiss_later :a, :b, c: 1, d: 2, e: 4
      TestBunny.new.perform_kiss_later :a, :b, c: 1, d: 2, e: 4

      assert_equal(
        ["Mmmmuah! [a, b, 1, 4]", "Smooch! [a, b, 1, 4]"],
        TestBunny.state.sort
      )
    end
  end

  test "class methods are jobified first, so class methods can be jobified by POROs with same-name instance methods" do
    perform_enqueued_jobs do
      TestBunny.perform_class_methods_are_jobified_first_later

      assert_raises do
        TestBunny.new.perform_class_methods_are_jobified_first_later
      end
    end
  end

  test "methods ending with ? become perform_xyz_later?" do
    perform_enqueued_jobs do
      TestBunny.reset_state
      TestBunny.perform_kiss_later?

      assert_equal(
        ["Kiss?"],
        TestBunny.state.sort
      )
    end
  end

  test "methods can have ! in name" do
    perform_enqueued_jobs do
      TestBunny.reset_state
      TestBunny.perform_kiss_later!

      assert_equal(
        ["Kiss!"],
        TestBunny.state.sort
      )
    end
  end

  if BENCHMARK
    test "benchmark" do
      perform_enqueued_jobs do
        # Define and jobify a method BOOT_BENCHMARK_ITERATIONS times
        BENCHMARK.times do |i|
          TestBunny.send(:define_method, "boot_benchmark_#{i}") do
            "boot_benchmark_#{i}"
          end
          JobifyBenchmark.benchmark(:boot) { TestBunny.send(:jobify, "boot_benchmark_#{i}".to_sym) }
        end

        (BENCHMARK / 2).times do
          JobifyBenchmark.benchmark(:perform) { TestBunny.perform_kiss_later :a, :b, c: 1, d: 2, e: 4 }
          JobifyBenchmark.benchmark(:perform) { TestBunny.new.perform_kiss_later :a, :b, c: 1, d: 2, e: 4 }
        end

        BENCHMARK.times do |_i|
          JobifyBenchmark.benchmark(:perform_control) { BenchmarkControlJob.perform_later }
        end

        puts ""
        JobifyBenchmark.print
        puts ""
      end
    end
  end
end
