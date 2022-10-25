# frozen_string_literal: true

# noinspection RubyClassVariableUsageInspection
class JobifyBenchmark
  @@test_benchmark = {
    perform: { count: 0, elapsed: 0 },
    perform_control: { count: 0, elapsed: 0 },
    boot: { count: 0, elapsed: 0 }
  }

  def self.benchmark(key, &block)
    @@test_benchmark[key][:count]   += 1
    @@test_benchmark[key][:elapsed] += Benchmark.ms(&block)
  end

  def self.print
    %i[boot perform perform_control].each do |key|
      elapsed = @@test_benchmark[key][:elapsed] / @@test_benchmark[key][:count]
      puts "Benchmark #{key}: #{elapsed.round(3)} ms on avg of #{@@test_benchmark[key][:count]} iterations"
    end
    # puts "Benchmark #{key}: #{@@test_benchmark["#{key}_elapsed".to_sym]} ms total"
  end
end
