require 'rubygems'
require 'forkomatic'

class Tester < Forkomatic
  class Tester::Job < Forkomatic::Job
    # Add a data accessor...
    attr_accessor :data

    # Overload the initialize function to include this worker's data section.
    def initialize(data)
      self.data = data
    end

    # Overload the work! function.
    def work!
      puts @data
      sleep rand(5)
    end
  end

  # Overload the build_jobs function to give each job useful work and data to work with.
  def build_jobs(count)
    puts "Existing children : #{child_pids.length}"
    puts "New this iteration: #{count}"
    (1..count).each.collect { Tester::Job.new(rand(20)) }
  end
end

# Create a new forkomatic instance with 3 child workers.
f = Tester.new({:max_children => 10, :work_interval => 1})
# Do the work
f.run
