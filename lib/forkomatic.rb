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
      params[:wait_for_children] = true
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

  # Kill all child processes and shutdown.
  def shutdown
    child_pids.each do |pid|
      begin
        Process.kill("TERM", pid)
      rescue => e
        puts e.to_s
      end
    end
    exit
  end

  # Do work.
  def run
    Signal.trap("INT")  { shutdown }
    iteration = 0
    while (@max_iterations.nil? || iteration < @max_iterations) do
      iteration += 1
      current_jobs = build_jobs(available)
      current_jobs.each do |job|
        pid = Process.fork do
          job.work!
        end
        job.pid = pid
        @jobs.push(job)
      end
      sleep @work_interval if @work_interval > 0
    end
    Process.waitall if @wait_for_children
  end

  # Create workers.
  def build_jobs(count)
    (1..count).each.collect {Forkomatic::Job.new}
  end

  # Reap child processes that finished.
  def reap(pid)
    return true if pid.nil?
    begin
      return true if Process.waitpid(pid, Process::WNOHANG)
    rescue Errno::ECHILD
      return true
    rescue => e
      puts "ERROR: #{e.to_s}"
    end
    return false
  end

  # Try to reap all child processes.
  def reap_all
    finished = []
    @jobs.each do |job|
      if reap(job.pid)
        finished.push(job.pid)
      end
    end
    @jobs.delete_if {|job| finished.include?(job.pid)}
  end

  # See how many children are available.
  def available
    # Initialize if need be.
    return @max_children if @jobs.nil? || @jobs.empty?
    # Reap children runners without waiting.
    reap_all
    @max_children - @jobs.length
  end

  # Get a list of current process IDs.
  def child_pids
    reap_all
    pids = []
    @jobs.each {|job| pids.push(job.pid) if job.pid}
    pids
  end
end
