#!/usr/bin/env ruby
require 'simplecov'
SimpleCov.start

require 'minitest/reporters'
require 'minitest/autorun'
MiniTest::Reporters.use! [MiniTest::Reporters::DefaultReporter.new,
                          MiniTest::Reporters::JUnitReporter.new]
require_relative '../lib/GitHubDownloader'

class TestGitHubDownloader < MiniTest::Test

  def setup()
    @downloader = GitHubDownloader.new(project_repo: 'project/testrepo')
  end

  def test_initialize()
    branch = 'test_branch'
    # downloader = GitHubDownloader.new(project_repo: 'project/testrepo')
    assert_kind_of(GitHubDownloader, @downloader)
    assert_equal('https://github.com/project/testrepo/archive/master.zip', @downloader.url)
    assert_equal('master', @downloader.branch)
    downloader = GitHubDownloader.new(project_repo: 'project/testrepo', branch: 'test_branch')
    assert_equal('https://github.com/project/testrepo/archive/test_branch.zip', downloader.url)
    assert_equal('test_branch', downloader.branch)
  end

  def test_url_exist?()
    url = 'https://github.com/notarealrepo1234567890'
    assert_equal("NotFound - #{url}", @downloader.url_exist?(url))
    url = 'https://github.com/'
    assert_equal(url, @downloader.url_exist?(url))
  end
end
