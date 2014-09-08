require 'open3'

require 'snipr/version'
require 'snipr/output'
require 'snipr/process_locator'
require 'snipr/process_signaller'

module Snipr
  ##
  # Error raised when a system command fails
  class ExecError < StandardError; end

  ##
  # Executes a command, returning the output as
  # an array of lines.  Raises an ExecError if the
  # command did not execute cleanly.
  def self.exec_cmd(command)
    Open3.popen3(command) do |stdin, stdout, stderr|
      err = stderr.read
      raise ExecError, err unless err.empty?
      stdout.read.split("\n")
    end
  end
end
