require 'time'

module Snipr
  ##
  # Class for writing to standard error & standard out in a
  # uniform way.
  class Output
    ##
    # Write a message prepended with an ISO8601 timestamp to
    # STDOUT
    def info(msg)
      STDOUT.write("#{runtime} #{msg}\n")
    end

    ##
    # Write a message prepndend with an ISO8601 timestamp to
    # STDERR
    def err(msg)
      STDERR.write("#{runtime} #{msg}\n")
    end

    private
    def runtime
      Time.now.iso8601
    end
  end
end
