#!/usr/bin/ruby
require_relative 'GitHubDownloader'
require_relative 'Composer'
require 'docker'

# Main class for orchestrating docker compose stacks.
class ContainerMgmt
  def initialize(action: nil, project_repo: nil, branch: nil)
    @project_repo = project_repo
    @branch = if branch
                branch
              else
                'master'
              end
    @action = action
    @path = "#{File.dirname(__FILE__)}/../repos/#{@project_repo.split('/')[-1]}-#{@branch}/"
    @compose = Composer.new(@path)
  end

  # depending on the 'action' from the CLI perform various docker functions.
  def process()
    case @action
    when 'build'
      # downloads repo and builds the image
      @path = check_repo()
      build_image()
    when 'launch'
      # downloads repo, builds and launches image
      @path = check_repo()
      build_image()
      launch_stack()
    when 'relaunch'
      # performs a 'down' of the container and then updates from github and builds/launches again
      @compose.down
      @path = check_repo()
      build_image()
      launch_stack()
    when 'up'       then @compose.up
    when 'stop'     then @compose.stop
    when 'pause'    then @compose.pause
    when 'unpause'  then @compose.unpause
    when 'down'     then @compose.down
    when 'logs'     then @compose.logs
    when 'config'   then @compose.config
    end
  end

  def build_image()
    @compose.build
  end

  def launch_stack()
    @compose.launch
  end

  # checks if the application exists or is already running inside a container
  # before downloading
  def check_repo()
    if Dir.exist?(@path)
      compose = Docker::Compose::Session.new(dir: @path)
      if compose.ps.empty?
        path = retrieve_repo()
      end
    else
      path = retrieve_repo()
    end
    return path
  end

  # pulls down the archive from GitHub
  def retrieve_repo()
    puts 'updating repo'
    dloader = GitHubDownloader.new(project_repo: @project_repo, branch: @branch)
    path = dloader.retrieve_repo()
    return path
  end
end