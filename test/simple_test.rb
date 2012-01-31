require 'rubygems'
require 'forkomatic'

class Tester < Forkomatic
  class Tester::Job < Forkomatic::Job
    # Add a data accessor...
    attr_accessor :data

    # Overload the initialize function to include this worker's data section.
    def initialize(data, start, stop)
      self.data = (start..stop).collect {|i| data[i]}
    end

    # Overload the work! function.
    def work!
      @data.each {|d| puts d}
    end
  end

  # Overload the build_jobs function to give each job useful work and data to work with.
  def build_jobs(count)
    data = (1..100).each.collect
    i = 0
    (1..count).each.collect { i += 1; Tester::Job.new(data, i * (20 / count), (i + 1) * (20 / count) - 1)}
  end
end

# Create a new forkomatic instance with 20 child workers.
f = Tester.new(20)
# Do the work
f.run
