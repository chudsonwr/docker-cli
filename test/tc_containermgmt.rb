#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'minitest/autorun'
MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]
require_relative '../lib/ContainerMgmt'

class TestContainerMgmt < MiniTest::Test

  def setup()
    @container = ContainerMgmt.new(action: 'config', project_repo: 'test/test', branch: 'master', proxy: true)
  end

  def test_initialize()
    assert_kind_of(ContainerMgmt, @container)
    assert_equal('config', @container.action)
    assert_equal('test/test', @container.project_repo)
    assert_equal('master', @container.branch)
    assert_equal(true, @container.proxy)
    assert_equal('nginx-proxy', @container.proxy_net)
    container = ContainerMgmt.new(action: 'config', project_repo: 'test/test', branch: 'master')
    assert_equal(nil, container.proxy_net)
    assert_equal(false, container.proxy)
  end

  def test_update_db_element()
    obj = YAML.load_file("#{File.dirname(__FILE__)}/testdata/test_default_compose.yml")
    assert_equal(true, @container.update_db_element(obj)['services'].include?("db-#{@container.branch}"))
  end

  def test_update_virtual_host()
    Dir.glob("#{File.dirname(__FILE__)}/testdata/**/*").each do |file_path|
      obj = YAML.load_file(file_path)
      assert_kind_of(Array,  @container.update_virtual_host(obj)['services']['web']['environment'])
      assert_equal("VIRTUAL_HOST=#{@container.branch}.dev.com", @container.update_virtual_host(obj)['services']['web']['environment'].find { |x| x == "VIRTUAL_HOST=#{@container.branch}.dev.com" })
    end
    obj = YAML.load_file("#{File.dirname(__FILE__)}/testdata/test_vh_array.yml")
    assert_equal(2, @container.update_virtual_host(obj)['services']['web']['environment'].count)
    obj = YAML.load_file("#{File.dirname(__FILE__)}/testdata/test_vh_string2.yml")
    assert_equal(2, @container.update_virtual_host(obj)['services']['web']['environment'].count)
  end

  def test_covert_to_array
    obj = YAML.load_file("#{File.dirname(__FILE__)}/testdata/test_vh_string2.yml")
    assert_kind_of(Array, @container.update_virtual_host(obj)['services']['web']['environment'])
  end

  def test_add_net_element()
    Dir.glob("#{File.dirname(__FILE__)}/testdata/**/*").each do |file_path|
      obj = YAML.load_file(file_path)
      assert_equal({'name' => 'nginx-proxy'}, @container.add_net_element(obj)['networks']['default']['external'])
    end
    obj = YAML.load_file("#{File.dirname(__FILE__)}/testdata/test_vh_array.yml")
    assert_equal({'name' => 'internal-network'}, @container.add_net_element(obj)['networks']['default']['internal'])
  end
end
