#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'minitest/autorun'
MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]
require_relative '../lib/ContainerMgmt'

class TestComposer < MiniTest::Test

  def setup()
    @container = ContainerMgmt.new(action: 'config', project_repo: 'test/test', branch: 'master')
  end

  def test_initialize()
    assert_kind_of(ContainerMgmt, @container)
  end
end
