#!/usr/bin/ruby
require 'optparse'
require 'ostruct'
require 'json'
require_relative '../lib/GitHubDownloader'
require_relative '../lib/Composer'
require_relative '../lib/ContainerMgmt'

# Shim for launching the ContainerMgmt orchestration class
class Provisioner
  def initialize(opts = {})
    @opts = opts
  end

  # Define the allowed actions
  def self.actions
    return ['build', 'launch', 'pause', 'unpause', 'down', 'logs', 'up', 'stop', 'relaunch', 'config']
  end

  def supported_action(action)
    return self.class.actions().any? { |a| a.casecmp(action).zero? }
  end

  def set_action(action)
    if supported_action(action)
      @opts[:action] = action.downcase()
      return true
    else
      puts "[Provisioner] Unsupported Action: #{action}"
      return false
    end
  end

  # Main method to launch the ContainerMgmt class
  def provision()
    ContainerMgmt.new(action: @opts[:action].to_s, project_repo: @opts[:github], branch: @opts[:version]).process()
  end
end

# Raie an exception for any required args if missing
def missing_args()
  raise OptionParser::MissingArgument, "You're missing the --github project repository argument" if @options.github.nil?
end

# OptionParser to define allowed arguments/options
def parse_args(args)
  opt_parser = OptionParser.new do |opts|
    opts.banner = 'Usage: provision.rb [options]'
    opts.on('--action [TYPE]', Provisioner.actions(),
            'Select action type (deploy, delete)') do |a|
      @options.action = a
    end
    opts.on('-g', '--github Project/REPO', 'The project/REPO from GitHub you want to build') do |github|
      @options.github = github
    end
    opts.on('-v', '--version VERSION', 'The branch or commit hash to build') do |version|
      @options.version = version
    end
  end

  opt_parser.parse!(args)
  missing_args()
end

#--------------------------------------------
# Execution point...
#--------------------------------------------
if __FILE__ == $PROGRAM_NAME
  # Setup command line arguments
  @options = OpenStruct.new
  @options.action = 'launch'
  @options.github = nil
  @options.version = 'master'

  parse_args(ARGV)

  provisioner = Provisioner.new(@options.to_h())
  provisioner.provision()
end
