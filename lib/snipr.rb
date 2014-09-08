require 'open3'

require "snipr/version"
require 'snipr/process_locator'

module Snipr
  ##
  # Error raised when a system command fails
  class ExecError < StandardError; end

  ##
  # Executes a command, returning the output as
  # an array of lines.  Raises an ExecError if the
  # command did not execute cleanly.
  def self.exec_cmd(command)
    stdout, stderr, status = Open3.capture3(command)
    if status == 0
      stdout.split("\n")
    else
      raise ExecError, "#{status} #{stderr}"
    end
  end
end
