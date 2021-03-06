require 'forwardable'

module Snipr
  ##
  # Class that can send signals to targetted processes or their
  # parent processes and invoke callbacks around the actions.  Delegates
  # process location to a ProcessLocator.  Is configured using a
  # block on initialization as follows:
  #
  # signaller = ProcessSignaller.new do |signaller|
  #   signaller.include       /resque/
  #   signaller.exclude       /scheduler/
  #   signaller.signal        "USR1"
  #   signaller.target_parent false
  #   singaller.dry_run
  #
  #   signaller.on_no_processes do
  #     puts "No processes"
  #   end
  #
  #   signaller.before_signal do |signal, process|
  #     puts "Sending #{signal} to #{process.pid}"
  #   end
  #
  #   signaller.after_signal do |signal, process|
  #     puts "Sent #{signal} to #{process.pid}"
  #   end
  #
  #   signaller.on_error do |e, signal, process|
  #     puts "Ooops, got #{e} sending #{signal} to #{process.pid}"
  #   end
  # end
  #
  # signaller.send_signals
  #
  class ProcessSignaller
    extend Forwardable
    def_delegators :locator, :include, :exclude, :memory_greater_than,
                   :cpu_greater_than, :alive_longer_than, :filter

    attr_reader :signal
    attr_writer :locator

    def initialize(&block)
      @locator = ProcessLocator.new
      on_no_processes {}
      before_signal {}
      after_signal {}
      on_error {|e, process, signal| raise e}
      block.call(self)
    end

    ##
    # Send the specified signal to all located processes, invoking
    # callbacks as appropriate.
    def send_signals
      processes = @locator.locate

      if processes.empty?
        @on_no_processes.call
      else
        processes.each do |process|
          signal_process(process)
        end
      end
    rescue StandardError => e
      @on_error.call(e)
    end

    ##
    # Specify the signal to send to the targetted processes.  This should
    # be a string that maps one of the values listed here:
    #
    # http://ruby-doc.org/core-1.8.7/Signal.html#method-c-list
    def signal(signal)
      @signal = Signal.list[signal.to_s.upcase].tap do |sig|
        unless sig
          raise "'#{signal}' not found -- see http://ruby-doc.org/core-1.8.7/Signal.html#method-c-list"
        end
      end
    end

    ##
    # Specify or access the locator collaborator that is responsible for
    # collecting the processes to operate on
    def locator(locator=nil)
      @locator ||= (locator || ProcessLocator.new)
    end

    ##
    # Callback invoked when no processes are found
    def on_no_processes(&callback)
      @on_no_processes = callback
    end

    ##
    # Callback invoked immediately before sending a signal to a process.
    # Will send both the signal and the KernelProcess object as returned
    # by the locator.
    def before_signal(&callback)
      @before_signal = callback
    end

    ##
    # Callback invoked immediately after sending a signal to a process.
    # Will send both the signal and the KernelProcess object as returned
    # by the locator.
    def after_signal(&callback)
      @after_signal = callback
    end

    ##
    # Callback invoked if an error is encountered.  If this is within
    # the context of attempting to send a signal to a process, then
    # the exception, signal and KernelProcess object are sent.  Otherwise,
    # only the exception is sent.
    def on_error(&callback)
      @on_error = callback
    end

    ##
    # Set to true if the signal should be sent to the parent of any
    # located processes.  Defaults to false.
    def target_parent(flag=false)
      @target_parent = flag
    end

    ##
    # Invoke if you want to have callbacks invoked, but not actually
    # send signals to located processes.
    def dry_run
      @dry_run = true
    end

    ##
    # Use pkill to ensure that the process we are attempting to signal
    # matches what we know about it. This only works for the
    # targetted process, not the parent.
    def pkill
      @pkill = which("pkill")
      raise "pkill not found in path or is not executable!" unless @pkill
    end

    # Determine if a command exists in our PATH
    def which(cmd)
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        location = File.join(path, cmd)
        return location if File.executable?(location)
      end
      return nil
    end

    ##
    # Ensure that the PID we are attempting to kill still matches what we expect
    # This is not used when pkill option is set
    def cmd_matches?(process)
       process.command == Snipr.exec_cmd("ps -p #{process.pid} -o 'command='").first.strip
    end

    def ppid_matches?(process)
      Integer(process.ppid) == Integer(Snipr.exec_cmd("ps -p #{process.pid} -o 'ppid='").first.strip)
    end

    def process_matches?(process)
      cmd_matches?(process) && ppid_matches?(process)
    end

    private
    def signal_process(process)
      @before_signal.call(@signal, process)
      unless @dry_run
        if @target_parent
          Process.kill(@signal, process.ppid) if process_matches?(process)
        else
          if @pkill
            system("#{@pkill} --signal #{@signal} -P #{process.ppid} -f \"^#{Regexp.escape(process.command)}\"")
          else
            Process.kill(@signal, process.pid) if process_matches?(process)
          end
        end
      end
      @after_signal.call(@signal, process)
    rescue StandardError => e
      @on_error.call(e, @signal, process)
    end
  end
end
