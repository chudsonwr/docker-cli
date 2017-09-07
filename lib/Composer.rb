require 'docker/compose'
require 'json'

class Composer
  def initialize(directory, logger: nil)
    @compose = Docker::Compose::Session.new(dir: directory)
    @clilog = logger
  end

  def stop()
    @compose.stop
  end

  def restart()
    @compose.restart
  end

  def pause()
    @compose.pause
  end

  def unpause()
    @compose.unpause
  end

  def build()
    @compose.build
  end

  def up()
    launch()
  end

  def down()
    @compose.down
  end

  def logs()
    @compose.logs
  end

  def processes()
    @compose.ps
  end

  def config()
    @compose.config
  end

  def update_port(compose_object)
    config = compose_object.config
    @clilog.debug(config)
    file = compose_object.dir + compose_object.file
    @clilog.debug(file)
    local_port = config['services']['web']['ports'][0].split(':')[1]
    old_port = config['services']['web']['ports'][0].split(':')[0]
    new_port = old_port.to_i + 1
    config['services']['web']['ports'][0] = "#{new_port}:#{local_port}"
    write_config_to_disk(config, file)
    @clilog.debug("the port specified, #{old_port}, was already in use. Incrementing by 1 and retrying.")
  end

  def write_config_to_disk(config, file_path)
    File.open(file_path, 'w') do |file|
      file.write config.to_yaml
    end
  end

  def launch()
    x = false
    count = 0
    until x == true || count > 10
      begin
        @compose.up(detached: true)
        x = true
      rescue => e
        if e.detail.include?('port is already allocated')
          update_port(@compose)
          count += 1
        else
          @clilog.fatal(e)
          exit
        end
      end
    end
  end
end
