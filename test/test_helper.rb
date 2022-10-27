# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "jobify"
require "jobify_benchmark"
require "minitest/autorun"

# Benchmark speed? Set false to skip
BENCHMARK = ENV["BENCHMARK"].to_i.nonzero? ? ENV["BENCHMARK"].to_i : false
# Output job logs?
OUTPUT_JOB_LOGS        = ENV["OUTPUT_JOB_LOGS"] == "true"

# Silence ActiveJob unless we want to see it (output is good for debugging)
ActiveJob::Base.logger = Logger.new(nil) unless OUTPUT_JOB_LOGS
