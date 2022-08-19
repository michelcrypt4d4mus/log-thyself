# Run on 2022-08-15
#
# Filter count: 35
# Processed 79738 in 12.631s (6312.878 rows per second)
#
# Filter count: 18
# Processed 79738 in 12.09s (6595.454 rows per second)
#
# Filter count: 0
# Processed 79738 in 10.535s (7568.911 rows per second)

require 'benchmark'
#require 'profile'

ENV['RUNNING_FILTER_BENCHMARKS'] = 'true'
LogEventFilter.build_filters!


class FilterBenchmarker
  JSON_LOGS = File.join(Rails.root, 'log/benchmarking/benchmarking.json')
  SHELL_COMMAND = "cat \"#{JSON_LOGS}\""

  OPTIONS = {
    destination_klass: MacOsSystemLog,
    read_only: true,
    app_log_level: 'ERROR'
  }

  def self.run_test
    rows_read = 0

    execution_time = Benchmark.measure {
      rows_read = StreamCoordinator.collect!(AppleJsonLogStreamParser.new(SHELL_COMMAND), OPTIONS)
    }

    rows_per_second = rows_read / execution_time.real
    puts "\nFilter count: #{LogEventFilter.filters.count}"
    puts "Processed #{rows_read} in #{execution_time.real.round(3)}s (#{rows_per_second.round(3)} rows per second)\n\n"
  end
end

initial_filter_count = LogEventFilter.filters.count
FilterBenchmarker.run_test
LogEventFilter.filters = LogEventFilter.filters[0..(initial_filter_count / 2.0).to_i]
FilterBenchmarker.run_test
LogEventFilter.filters = []
FilterBenchmarker.run_test
