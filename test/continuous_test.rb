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
      sleep 1
    end
  end

  attr_accessor :data
  # Overload the build_jobs function to give each job useful work and data to work with.
  def build_jobs
    @data ||= 0
    available.each {|id| @data += 1; @jobs[id] = Tester::Job.new(@data)}
  end
end

# Create a new forkomatic instance with 3 child workers.
f = Tester.new({:max_children => 5, :work_interval => 0, :wait_for_children => false})
# Do the work
f.run
