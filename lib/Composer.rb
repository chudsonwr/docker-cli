require 'docker/compose'
require 'json'

class Composer
  def initialize(directory)
    @compose = Docker::Compose::Session.new(dir: directory)
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

  def launch()
    begin
      @compose.up(detached: true)
    rescue => e
      puts e
      exit
    end
  end
end
