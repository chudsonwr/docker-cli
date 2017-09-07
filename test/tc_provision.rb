#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'minitest/autorun'
MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]
require_relative '../bin/provision'

class TestProvisioner < MiniTest::Test

  def setup()
    @options = {:action=>"logs", :github=>"notapro/repo", :version=>"master"}
    @provisioner = Provisioner.new(@options)
  end

  def test_initialize()
    assert_kind_of(Provisioner, @provisioner)
  end

  def test_set_action()
    actions = ['build', 'launch', 'pause', 'unpause', 'down', 'logs', 'up', 'stop', 'relaunch', 'config']
    actions.each do |action|
      assert_equal(true, @provisioner.set_action(action))
    end
    assert_equal(false, @provisioner.set_action('notarelaaction'))
  end
end
