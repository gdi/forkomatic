require 'rubygems'
require 'forkomatic'

$range = 1000000
$data = (1..$range).each.collect
$search_key = rand($range)
$found = false

class Tester < Forkomatic
  class Tester::Job < Forkomatic::Job
    # Beginning and end index to search
    attr_accessor :start
    attr_accessor :stop

    # Overload the initialize function to include this worker's data section.
    def initialize(start, stop)
      self.start = start
      self.stop = stop
    end

    # Overload the work! function.
    def work!
      (@start..@stop).each {|i| return if $found; d = $data[i]; $found = true and puts "Found #{d}" if d == $search_key }
    end
  end

  # Overload the build_jobs function to give each job useful work and data to work with.
  def build_jobs(count)
    (1..count).each.collect {|i| Tester::Job.new((i - 1) * ($range / count), i * ($range / count) - 1) }
  end
end

# Time execution with 1 child.
(1..4).each do |i|
  start = Time.now
  f = Tester.new(i)
  f.run
  stop = Time.now
  puts "Forks: #{i}, Execution time: #{(stop - start) * 1000}ms"
end
