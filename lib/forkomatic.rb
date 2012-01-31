class Forkomatic
  class Job
    attr_accessor :pid

    def initialize
      self.pid = nil
    end

    def work!
      sleep 1
    end
  end


  attr_accessor :child_pids
  attr_accessor :max_children
  attr_accessor :work_interval
  attr_accessor :max_iterations
  attr_accessor :jobs
  attr_accessor :wait_for_children

  # Initialize the runners.
  def initialize(args)
    params = {}
    if args.is_a?(String)
      # Load config from a file.
      params = load_config(args)
    elsif args.is_a?(Integer)
      # Given an integer, forkomatic will only run N runners 1 time.
      params[:max_children] = args
      params[:work_interval] = 0
      params[:max_iterations] = 1
    elsif args.is_a?(Hash)
      # Specify the parameters directly.
      params = args
    end
    t = params
    params.inject({}) {|t, (key, val)| t[key.to_sym] = val; t}
    self.jobs = []
    self.max_children = params[:max_children] || 1
    self.work_interval = params[:work_interval].nil? || params[:work_interval] < 0 ? 0 : params[:work_interval]
    self.max_iterations = params[:max_iterations]
    self.wait_for_children = params[:wait_for_children].nil? ? true : params[:wait_for_children]
  end

  # Load a configuration from a file.
  def load_config(config_file)
    params = {}
    # Allowed options.
    options = ['max_children', 'work_interval', 'max_iterations', 'wait_for_children']
    begin
      # Try to read the config file, and store the values.
      data = File.open(config_file, "r").read.split(/\n/)
      data.each do |line|
        if line =~ /^\s*([a-zA-Z_]+)\s+([0-9]+)/
          config_item = $1
          config_value = $2
          # Make sure option is valid.
          if options.map(&:downcase).include?(config_item.downcase)
            params[config_item.to_sym] = config_value.to_i
          end
        end
      end
    rescue => e
      puts "Error loading config file: #{e.to_s}"
    end
    params
  end

  # Do work.
  def run
    iteration = 0
    while (@max_iterations.nil? || iteration < @max_iterations) do
      iteration += 1
      available = self.available

      @jobs = build_jobs
      @jobs.each do |job|
        pid = Process.fork do
          job.work!
        end
        job.pid = pid
      end
      sleep @work_interval if @work_interval > 0
    end
    Process.waitall if @wait_for_children
  end

  # Create workers.
  def build_jobs
    count = self.available
    (1..count).collect {|i| Forkomatic::Job.new}
  end

  # Perform work in a parallel fashion.
  def available
    # Reap children runners without waiting.
    finished = []
    @jobs.each do |job|
      if job.pid
        begin
          finished.push(job.pid) if Process.waitpid(job.pid, Process::WNOHANG)
        rescue Errno::ECHILD
          finished.push(job.pid)
        rescue

        end
      end
    end
    @jobs.delete_if {|job| finished.include?(job.pid) }
    @max_children - @jobs.length
  end

  # Get a list of current process IDs.
  def pids
    pids = []
    @jobs.each {|job| pids.push(job.pid) if job.pid}
    pids
  end
end
