module Snipr
  ##
  # Simple data structure representing a kernel process
  KernelProcess = Struct.new(:pid,:ppid,:memory,:cpu,:etime,:seconds_alive,:command)

  ##
  # Responsible for locating running processes and returning an array
  # of KernelProcess objects that represent them.  Uses the output of
  # ps to locate processes, so this only works on *nix.  Tested on
  # RHEL 6.5 and Linux Mint
  class ProcessLocator
    DAY_SECONDS = 86400
    HOUR_SECONDS = 3600
    MINUTE_SECONDS = 60


    attr_accessor :signal
    attr_reader :includes, :excludes, :filters

    def initialize
      @includes = []
      @excludes = []
      @filters = []
    end

    ##
    # Locates the processes that match all include patterns and do not
    # match all exclude patterns
    def locate
      processes = includes.reduce(all_processes, &by_inclusion_patterns)
      processes = excludes.reduce(processes, &by_exclusion_patterns)
      processes = filters.reduce(processes, &by_filter)
    end

    ##
    # Define a pattern that the command portion of the ps command must match to
    # include the process.  Multiple patterns can be defined and all must be
    # matched
    def include(pattern)
      includes << pattern
    end

    ##
    # Define a pattern that the command portion of the ps command must match to
    # exclude the process.  Multiple patterns can be defined and all will be
    # rejected.
    def exclude(pattern)
      excludes << pattern
    end

    ##
    # Define a size in bytes that processes must be greater than to be included
    # in the result.
    def memory_greater_than(bytes)
      filter { |process| process.memory > bytes }
    end

    ##
    # Define a cpu use percentage that processes must be greater than to be
    # included in the result.
    def cpu_greater_than(percent)
      filter {|process| process.cpu > percent}
    end

    ##
    # Define a time in seconds that processes must have been alive for longer
    # than to be included in results
    def alive_longer_than(sec)
      filter {|process| process.seconds_alive > sec}
    end

    ##
    # Define your own filter using a lambda that receives a KernelProcess object
    # and returns true if the process should be included in results
    def filter(&callable)
      filters << callable
    end

    private
    def clear!
      @includes = []
      @excludes = []
    end

    def by_inclusion_patterns
      lambda {|processes, filter| processes.select(&match(filter))}
    end

    def by_exclusion_patterns
      lambda {|processes, filter| processes.reject(&match(filter))}
    end

    def by_filter
      lambda {|processes, filter| processes.select(&filter)}
    end

    def match(filter)
      lambda {|process| process.command.match(filter)}
    end

    def all_processes
      Snipr.exec_cmd('ps h -eo pid,ppid,size,%cpu,etime,cmd').map do |line|
        pid, ppid, mem, cpu, etime, *cmd = line.split
        cmd = cmd.join(" ")

        KernelProcess.new(
          pid.to_i,
          ppid.to_i,
          mem.to_i,
          cpu.to_f,
          etime,
          parse_seconds(etime),
          cmd
        )
      end
    end

    ##
    # Parses etime, which is in the format dd-hh:mm:ss
    # dd- will be omitted if the run time is < 24 hours
    # hh: will be omitted if the run time is < 1 hour
    def parse_seconds(etime)
      time, days = etime.split("-").reverse
      sec, min, hr = time.split(":").reverse

      total = 0
      total += days.to_i * DAY_SECONDS if days
      total += hr.to_i * HOUR_SECONDS if hr
      total += min.to_i * MINUTE_SECONDS if min
      total += sec.to_i if sec
      total
    end
  end
end
