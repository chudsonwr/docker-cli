#!/usr/bin/ruby
require_relative 'GitHubDownloader'
require_relative 'Composer'
require 'docker'

# Main class for orchestrating docker compose stacks.
class ContainerMgmt
  def initialize(logger: nil, action: nil, project_repo: nil, branch: nil, proxy: false)
    @clilog = logger
    @proxy = proxy
    @project_repo = project_repo
    @branch = if branch
                branch
              else
                'master'
              end
    @action = action
    @path = "#{File.dirname(__FILE__)}/../repos/#{@project_repo.split('/')[-1]}-#{@branch}/"
    @compose = Composer.new(@path, logger: @clilog)
    @proxy_net = 'nginx-proxy' if @proxy
  end

  attr_reader :action
  attr_reader :branch
  attr_reader :project_repo
  attr_reader :path
  attr_reader :proxy
  attr_reader :proxy_net

  # depending on the 'action' from the CLI perform various docker functions.
  def process()
    # Start the proxy network and nginx reverse proxy container
    if @proxy
      start_network()
      start_proxy()
    end
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
      stop_network()
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

  # Allows nginx to set configs for each container launched.
  def start_network()
    network = Docker::Network.all.find { |network| network.info['Name'] == @proxy_net }
    @clilog.debug('starting the proxy network') unless network
    Docker::Network.create(@proxy_net) unless network
  end

  # Stops the proxy network
  def stop_network()
    network = Docker::Network.all.find { |network| network.info['Name'] == @proxy_net }
    @clilog.debug('Stopping the proxy network') if network
    Docker::Network.remove(@proxy_net) if network
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
    update_repo_with_version() if @proxy
    return path
  end

  # Main method for updating the Rails and docker files to allow multiple versions to run.
  def update_repo_with_version()
    update_compose_file()
    update_rails_db_connection("#{@path}config/database.yml")
  end

  # updates the compose file with a unique value for VIRTUAL_HOST which is required for the nginx reverse proxy
  # updates the db service in compose to be unique
  # updtes the virtual host for reverse proxy to be unique
  def update_compose_file()
    file_path = "#{@path}docker-compose.yml"
    obj = YAML.load_file(file_path)
    obj = update_db_element(obj)
    obj = add_net_element(obj)
    obj = update_virtual_host(obj)
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
  
  # Update db in compose file object
  def update_db_element(obj)
    obj['services']["db-#{@branch}"] = obj['services']['db']
    obj['services']['web']['depends_on'] = ["db-#{@branch}"]
    obj['services'].delete('db')
    return obj
  end

  # COonverts a single string entry for envronment variables in docker compose object into an array
  def convert_to_array(obj)
    if obj['services']['web']['environment'].class == String
      obj['services']['web']['environment'] = [obj['services']['web']['environment']]
    end
    obj
  end

  # Updates or adds the virtual host env var in a docker compose object
  def update_virtual_host(obj)
    if obj['services']['web']['environment'].is_a? String
      obj = convert_to_array(obj)
      obj = update_virtual_host(obj)
    elsif obj['services']['web']['environment'].is_a? Array
      if obj['services']['web']['environment'].find { |obj| obj[0..12] == 'VIRTUAL_HOST=' }.nil?
        obj['services']['web']['environment'] << "VIRTUAL_HOST=#{@branch}.dev.com"
      else
        obj['services']['web']['environment'].find { |obj| obj[0..12] == 'VIRTUAL_HOST=' }.replace("VIRTUAL_HOST=#{@branch}.dev.com")
      end
    else
      obj['services']['web']['environment'] = ["VIRTUAL_HOST=#{@branch}.dev.com"]
    end
    obj
  end

  # Adds the networks element to the compose file if it's not already there
  def add_net_element(obj)
    unless obj.dig('networks', 'default', 'external', 'name') == @proxy_net
      obj['networks'] = {"default"=>{"external"=>{"name" => @proxy_net}}} unless obj.dig('networks')
      obj['networks']['default'] = {"external"=>{"name" => @proxy_net}} unless obj.dig('networks', 'default')
      obj['networks']['default']['external'] = {"name" => @proxy_net}
    end
    return obj
  end

  # delete all running containers
  def delete_all_containers()
    containers = Docker::Container.all(all: true)
    containers.each do |container|
      @clilog.debug("Stopping container: #{container.name}")
      container.stop
      @clilog.debug("Deleting container: #{container.name}")
      container.delete
    end
  end

  # deletes all local images
  def delete_all_images()
    images = Docker::Image.all(all: true)
    images.each do |image|
      begin
        @clilog.debug("Deleting image: #{image.name}")
        image.remove
      rescue => e
        @clilog.error(e)
      end
    end
  end
end
