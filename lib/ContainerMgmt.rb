#!/usr/bin/ruby
require_relative 'GitHubDownloader'
require_relative 'Composer'
require 'docker'

# Main class for orchestrating docker compose stacks.
class ContainerMgmt
  def initialize(logger: nil, action: nil, project_repo: nil, branch: nil)
    @clilog = logger
    @project_repo = project_repo
    @branch = if branch
                branch
              else
                'master'
              end
    @action = action
    @path = "#{File.dirname(__FILE__)}/../repos/#{@project_repo.split('/')[-1]}-#{@branch}/"
    @compose = Composer.new(@path, logger: @clilog)
  end

  # depending on the 'action' from the CLI perform various docker functions.
  def process()
    start_network()
    start_proxy()
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
    when 'clean_all'
      delete_all_containers()
      delete_all_images()
    end
  end

  def build_image()
    @compose.build
  end

  def launch_stack()
    @compose.launch
  end

  # Starts nginx proxy to allow multiple sites hosted from the same tcp Port based on host-headers
  def start_proxy()
    proxy_compose = Composer.new("#{File.dirname(__FILE__)}/../proxy", logger: @csilog)
    status = proxy_compose.processes
    @clilog.debug('starting the proxy server') if status.empty?
    proxy_compose.launch if status.empty?
  end

  # Allows nginx to set configs for each container launched. Requires that the application 
  # you're building has a docker-compose file that references this network
  def start_network()
    network_name = 'nginx-proxy'
    network = Docker::Network.all.find { |network| network.info['Name'] == network_name }
    @clilog.debug('starting the proxy network') unless network
    Docker::Network.create(network_name) unless network
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
    @clilog.info('Updating Repo')
    dloader = GitHubDownloader.new(project_repo: @project_repo, branch: @branch, logger: @csilog)
    path = dloader.retrieve_repo()
    update_repo_with_version()
    return path
  end

  # Updates the DB details in the app to allow multiple DB connections
  # required because all instances share the nginx docker network. :(
  def update_repo_with_version()
    update_compose_file()
    update_rails_db_connection("#{@path}config/database.yml")
  end

  # updates the compose file with a unique value for VIRTUAL_HOST which is required for the nginx reverse proxy
  # updates the db service in compose to be unique
  def update_compose_file()
    file_path = "#{@path}docker-compose.yml"
    obj = YAML.load_file(file_path)
    obj['services']["db-#{@branch}"] = obj['services']['db']
    obj['services']['web']['depends_on'] = ["db-#{@branch}"]
    obj['services']['web']['environment'].find { |obj| obj[0..12] == 'VIRTUAL_HOST=' }.replace("VIRTUAL_HOST=#{@branch}.dev.com")
    obj['services'].delete('db')
    @compose.write_config_to_disk(obj, file_path)
  end

  # updates the db connection info in the rails config/database.yml file to reflect the new unique db service in docker
  def update_rails_db_connection(file_path)
    obj = YAML.load_file(file_path)
    obj.each do |env|
      if env[1]['host'] then env[1]['host'] = "db-#{@branch}" end
    end
    @compose.write_config_to_disk(obj, file_path)
  end

  # delete all running containers
  def delete_all_containers()
    containers = Docker::Container.all(all: true)
    containers.each do |container|
      container.stop
      container.delete
    end
  end

  # deletes all local images
  def delete_all_images()
    images = Docker::Image.all(all: true)
    images.each do |image|
      begin
        image.remove
      rescue => e
        @clilog.error(e)
      end
    end
  end
end
