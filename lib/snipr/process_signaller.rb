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
    # Send the specified signal to all located processes
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

    def signal(signal)
      @signal = Signal.list[signal.to_s.upcase].tap do |sig|
        unless sig
          raise "'#{signal}' not found -- see http://ruby-doc.org/core-1.8.7/Signal.html#method-c-list"
        end
      end
    end

    def locator(locator=nil)
      @locator ||= (locator || ProcessLocator.new)
    end

    def on_no_processes(&callback)
      @on_no_processes = callback
    end

    def before_signal(&callback)
      @before_signal = callback
    end

    def after_signal(&callback)
      @after_signal = callback
    end

    def on_error(&callback)
      @on_error = callback
    end

    def target_parent(flag=false)
      @target_parent = flag
    end

    private
    def signal_process(process)
      @before_signal.call(@signal, process)
      if @target_parent
        Process.kill(@signal, process.ppid)
      else
        Process.kill(@signal, process.pid)
      end
      @after_signal.call(@signal, process)
    rescue StandardError => e
      @on_error.call(e, @signal, process)
    end
  end
end
