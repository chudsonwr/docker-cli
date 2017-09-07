#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'minitest/autorun'
MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]
require_relative '../lib/GitHubDownloader'

class TestComposer < MiniTest::Test

  def setup()
    @compose = Composer.new('testdata/')
  end

  def test_initialize()
    assert_kind_of(Composer, @compose)
    assert_kind_of(Hash, @compose.config)
    assert_equal('jwilder/nginx-proxy', compose.config['services']['nginx-proxy']['image'])
  end
end
