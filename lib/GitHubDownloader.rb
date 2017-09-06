#!/usr/bin/ruby
require 'uri'
require 'net/http'
require 'openssl'
require 'zip'

# Manages download of git repo as branch or commit
class GitHubDownloader
  def initialize(project_repo: nil, branch: nil)
    # If no branch specified assume master
    @branch = if branch
                branch
              else
                'master'
              end
    @url = "https://github.com/#{project_repo}/archive/#{@branch}.zip"
  end

  attr_reader :url
  attr_reader :branch

  def download_file(file_url)
    file_name = 'repo.zip'
    # Create directory to store repo in
    directory = "#{File.dirname(__FILE__)}/../repos"
    Dir.mkdir(directory) unless Dir.exist?(directory)
    file_path = "#{directory}/#{file_name}"
    # Get a zipped up copy of the repo
    uri = URI.parse(file_url)
    http = Net::HTTP.new(uri.host, uri.port, nil)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    request = Net::HTTP::Get.new(uri.request_uri)
    resp = http.request(request)
    # Write the response to disk
    File.open(file_path, 'w') { |file| file.write(resp.body) }
    # Return the full path to the zip file
    return file_path
  end

  def url_exist?(url_string, limit = 10)
    # Check if the project/repo/branch provided actually exists.
    raise ArgumentError, 'Too many redirects' if limit.zero?
    url = URI(url_string)
    req = Net::HTTP.new(url.host, url.port, nil)
    req.use_ssl = (url.scheme == 'https')
    req.verify_mode = OpenSSL::SSL::VERIFY_NONE
    path = url.path unless url.path.nil?
    res = req.request_head(path || '/')
    # Github archives are redirected to a new location. loop through the redirects to get to the final URL. 
    case res
    when Net::HTTPSuccess then url_string
    when Net::HTTPRedirection then url_exist?(res['location'], limit - 1)
    when Net::HTTPNotFound then "NotFound - #{url_string}"
    else
      res.error!
    end
  end

  def unzip_file(file, destination)
    # Create an empty variable to assign the uncompressed directory name to
    zip_name = ''
    # Used to determine the uncompressed file directory name
    regex = "([a-zA-Z0-9]*-#{@branch}\/)"
    # unzip the contents
    Zip::File.open(file) do |zip_file|
      # Determine the uncompressed root directory name
      zip_name = zip_file.entries.find { |entry| entry.name.match(regex) }
      zip_file.each do |f|
        f_path = File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        # If the target file already exists we want to overwrite it to account for any changes in teh code
        FileUtils.rm_rf(f_path) if File.exist?(f_path)
        zip_file.extract(f, f_path)
      end
    end
    # Return the complete path to the uncompressed directory
    return "#{destination}/#{zip_name.name}" unless zip_name.nil?
  end

  def retrieve_repo()
    # verify the project/repo/branch actually exists
    final_url = url_exist?(@url)
    if final_url[0..7] == 'https://'
      # download the repo as an archive
      file_path = download_file(final_url)
      # unzip the archive
      unzipped = unzip_file(file_path, "#{File.dirname(__FILE__)}/../repos")
      # remove compressed archive file once unzipped
      FileUtils.rm_rf(file_path) if unzipped
      return unzipped
    else
      puts "We couldn't find the repo specified, here is the error."
      puts final_url
      exit
    end
  end
end
