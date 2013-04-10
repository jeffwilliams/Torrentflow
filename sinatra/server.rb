#!/usr/bin/env ruby

# Setup the load path
if ! File.directory?("www-lib")
  $stderr.puts "The www-lib directory cannot be found. Make sure to run this script from the base installation directory, as 'sinatra/server.rb'"
  exit 1
end
if ! $:.include?("www-lib")
  $: << "www-lib"
end
if ! $:.include?("daemon")
  $: << "daemon"
end
if ! $:.include?("sinatra")
  $: << "sinatra"
end

require 'rubygems'
require 'sinatra'
require 'haml'
require 'functions'
require 'Mime'
require 'logger'
require 'logging'
require 'AppServerConfig'

set :protection, :except => :session_hijacking

# Enable session support in Sinatra
enable :sessions
disable :logging

# If this is set to false, then users don't have to login to manage torrents
AuthenticationEnabled = true
LogFileName = "logs/sinatra.log"
PidFile = "var/sinatra.pid"

# Set up initial logger
$logger = makeFileLogger(LogFileName, 5, 5000000)

$appserverConfig = AppServerConfig.new
def parseConfig
  configPath = nil
  
  # Find config file
  configPath = AppServerConfig::findConfigFile
  if ! configPath
    $logger.error "Can't locate config file #{AppServerConfig::TorrentConfigFilename}."
    exit 1
  end

  if ! $appserverConfig.load(configPath)
    $logger.error "Loading configuration file failed"
    exit 1
  end
end

# The $urlBasePath variable is used for handling reverse proxy setups where torrentflow
# is not running in the root of the proxying server.
# For example, say Apache is reverse proxying /torrentflow to Sinatra, then 
# you can add the line 
#   pub_url_base_path: torrentflow
# to torrentflowapp.conf and Sinatra will behave like the application is running on /torrentflow.
# Note that the files under public/ must also be moved to public/torrentflow for Sinatra to find them.
$urlBasePath = ""

configure do
  begin
    parseConfig

    $urlBasePath = $appserverConfig.urlBasePath
    #file = File.open(LogFileName, "a")
    # Use stdlib logger
    #logger = Logger.new(file, 4, 1048576)
    $logger = Logger.new($appserverConfig.logFile, $appserverConfig.logCount, $appserverConfig.logSize)
    $logger.level = $appserverConfig.logLevel
    def $logger.puts(s)
      self.info s
    end
    def $logger.write(s)
      self.info s
    end
    def $logger.flush
    end
    if $appserverConfig.logRequests
      use Rack::CommonLogger, $logger
    end
    $logger.info "Started"
    # Write pid to var/
    if File.exists?("var/")
      begin
        File.open(PidFile,"w") do |file|
          file.puts Process.pid.to_s
        end
      rescue
        $logger.error "Can't write pid to '#{PidFile}'. Continuing anyhow."
      end
    end
  rescue
    $logger.error "Setting up logger failed: #{$!}"
    exit 1
  end
end


# Function that helps when implementing handlers for get requests that expect a 
# JSON encoded array as a response.
#
# This function will yield a valid authenticated client session to the passed block
# and expects the block to return the resulting array to encode.
def handleJSONRequest
  result = nil 
  errorMessage = withAuthenticatedDaemonClient do |client|
    rc = yield client
    result = JSON.generate(rc)
    nil
  end
      
  if errorMessage
    result = JSON.generate([errorMessage])
  end 
  result
end

helpers do
  # Get the publicly visible URL of this application. This is basically the
  # same as the factory url() helper from Sinatra, except takes into account the $urlBasePath variable.
  def puburl(addr = nil, absolute = false, add_script_name = true)
    return addr if addr =~ /\A[A-z][A-z0-9\+\.\-]*:/
    uri = [host = ""]
    if absolute
      host << "http#{'s' if request.secure?}://"
      if request.forwarded? or request.port != (request.secure? ? 443 : 80)
        host << request.host_with_port
      else
        host << request.host
      end
    end
    uri << request.script_name.to_s if add_script_name
    if addr =~ /^\/(.*)/
      addr = "/#{$urlBasePath}#{$1}"
    else
      addr = "/#{$urlBasePath}#{addr}"
    end
    uri << (addr ? addr : request.path_info).to_s
    File.join uri
  end
end

############# Sinatra Handlers ###############

get "/#{$urlBasePath}" do

  authenticated = false
  errorMessage = withDaemonClient do |client|
    if sessionIsValid?(client, session)
      authenticated = true
    end
    nil
  end
  
  config = loadConfig{ |errMsg| errorMessage = errMsg }

  if ! authenticated && AuthenticationEnabled
    haml :login, :locals => {:error => errorMessage}
  else
    haml :index, :locals => {:displayShowStatus => config && config.displayTvShowSummary, 
                             :displayUsageTracking => config && config.enableUsageTracking,
                             :error => errorMessage }
  end
end

get "/#{$urlBasePath}files" do

  authenticated = false
  errorMessage = withDaemonClient do |client|
    if sessionIsValid?(client, session)
      authenticated = true
    end
    nil
  end
  
  if ! authenticated && AuthenticationEnabled
    haml :login, :locals => {:error => errorMessage}
  else
    haml :files
  end
  
end

# Handle a user login request
post "/#{$urlBasePath}login" do
  authenticated = false
  errorMessage = withDaemonClient do |client|
    err = nil
    params[:login].to_s
    sid = client.login( params[:login].to_s, params[:password].to_s)
    if sid
      # Login succeeded!
      session[:rubytorrent_sid] = sid
      authenticated = true
    else
      err = "Invalid login or password"
    end
    err
  end

  if ! authenticated && AuthenticationEnabled
    haml :login, :locals => {:error => errorMessage}
  else
    redirect to(puburl('/'))
  end
end

# Handle a user logout request
post "/#{$urlBasePath}logout" do
  errorMessage = withDaemonClient do |client|
    sid = session[:rubytorrent_sid]
    return if !sid
    client.logout(sid)
    nil
  end

  haml :login, :locals => {:error => errorMessage}
end

# Handle a request to get a list of torrent information.

def getTorrents
  torrentNameFilter = nil
  attribs = []
  hasName = false
  params.each do |k,v|
    if k == 'name'
      torrentNameFilter = v.to_s
      hasName = true
    end
    attribs.push k.to_sym
  end

  attribs.push :name if ! hasName

  handleGetTorrentsRequest(attribs, torrentNameFilter, session)
end

get "/#{$urlBasePath}get_torrents" do
  getTorrents
end

post "/#{$urlBasePath}get_torrents" do
  getTorrents
end

get "/#{$urlBasePath}get_alerts" do
  torrentNameFilter = params[:name]
  handleJSONRequest do |client|
    rc = nil
    torrents = client.getAlerts(torrentNameFilter)
    if torrents
      # Send the array of TorrentInfo objects as JSON
      rc = ["success"]
      # Limit to last 100 alerts
      maxAlerts = 100
      if torrents.size > maxAlerts
        rc.concat torrents[torrents.size-maxAlerts,maxAlerts]
      else
        rc.concat torrents
      end
    end
    rc
  end
end

get "/#{$urlBasePath}get_fsinfo" do

  handleJSONRequest do |client|
    fsInfo = client.getFsInfo
    rc = nil
    if fsInfo
      rc = ["success"]
      # Convert the fs info fields to a hash
      fsInfoHash = Hash.new
      fsInfoHash['freeSpace'] = fsInfo.freeSpace
      fsInfoHash['usedSpace'] = fsInfo.usedSpace
      fsInfoHash['totalSpace'] = fsInfo.totalSpace
      fsInfoHash['usePercent'] = fsInfo.usePercent
      rc.push fsInfoHash
    else
      rc = ["Error getting info: " + fsInfo.errorMsg]
    end
    rc
  end
end

get "/#{$urlBasePath}get_usage" do
  type = params[:type]
  qty = params[:qty]
  type = type.to_sym if type
  qty = qty.to_sym if qty

  handleJSONRequest do |client|
    rc = []
    # Special case: If type is not specified and qty is current, then
    # get the daily current and monthly current in that order and return them.
    buckets = nil
    if ! type && qty == :current
      buckets = client.getUsage(:daily, qty)
      buckets.concat(client.getUsage(:monthly, qty)) if buckets
    else
      buckets = client.getUsage(type, qty)
    end
    
    if buckets
      buckets = [buckets] if ! buckets.is_a?(Array)
     
      # Send the array of bucket objects as JSON
      encoded = buckets.collect{ |b|
        b
      }
      rc = ["success"]
      rc.concat encoded
    else
      rc = [client.errorMsg]
    end 
    rc
  end
end

get "/#{$urlBasePath}get_files" do
  dir = params[:dir]
  
  handleJSONRequest do |client|
    rc = []
    dirContents = client.listFiles(dir)
    if dirContents
      # Send the array of TorrentInfo objects as JSON
      encoded = dirContents.files.collect{ |f|
        {'name' => f.name, 'type' => f.type.to_s, 'size' => f.size, 'modified' => f.modified}
      }
      rc = ["success", dirContents.dir]
      rc.concat encoded
    else
      rc = [client.errorMsg]
    end 
    rc
  end
end

get "/#{$urlBasePath}modify_files" do
  handleJSONRequest do |client|
    rc = []
    errorMessage = nil

    # This URL expects the list of torrents to be passed as the value
    # of variables beginning with the text "check" (from checkbox input values)
    #
    itemList = []
    params.each do |k,v|
      itemList.push v.to_s if k =~ /^check/
    end

    # We expect the operation to perform to be passed as well
    # 
    operation = params[:operation]
    operation = nil if operation.length == 0
    
    if ! errorMessage && ! operation
      errorMessage = "modify_torrent expects the operation parameter to be passed"
    end
    
    if operation != "remove_torrent" && operation != "remove_files" && operation != "pause" && operation != "remove_torrent_files"
      errorMessage = "modify_torrent was passed an invalid operation '#{operation}'"
    end
    
    if ! errorMessage
      if operation == "remove_torrent"
        itemList.each{ |t|
          errorMessage = client.errorMsg if ! client.delTorrent(t)
        }
      elsif operation == "remove_torrent_files"
        itemList.each{ |t|
          errorMessage = client.errorMsg if ! client.delTorrent(t, true)
        }
      elsif operation == "pause"
        itemList.each{ |t|
          errorMessage = client.errorMsg if ! client.togglePaused(t)
        }
      elsif operation == "remove_files"
        itemList.each{ |t|
          errorMessage = client.errorMsg if ! client.delFile(t)
        }
      end
    end

    if errorMessage
      rc = [errorMessage]
    else
      rc = ["success"]
    end

    rc 
  end
end

get "/#{$urlBasePath}get_torrentgraphdata" do

  torrentName = CGI.unescape(params[:name])
  
  rc = nil
  errorMessage = nil
  errorMessage = withAuthenticatedDaemonClient do |client|
    points = client.getGraphInfo(torrentName)
    if ! points
      $logger.error "Retrieving graph data for torrent #{torrentName} failed"
      errorMessage = client.errorMsg
      rc = "Error, Error, Error\n"  
      errorMessage
    else
      rc = "Time,Download Rate,Upload Rate\n"
      points.each{ |p|
        rc << "#{"%.3f" % p.x},#{"%.3f" % p.value(0)},#{"%.3f" % p.value(1)}\n"
      }
      if points.size == 0
        rc << "0.0,0.0,0.0\n"
      end 
      nil
    end
  end
  
  if errorMessage
    $logger.error "Retrieving graph data for torrent #{torrentName} failed: #{errorMessage}"
    rc = "Error, Error, Error\n"
  end

  rc
end

get "/#{$urlBasePath}download_torrent" do
  handleJSONRequest do |client|
    rc = []
    url = params[:torrenturl]
    if url
      # Use a higher timeout here
      oldTimeout = client.readTimeout
      client.readTimeout = 12
      begin
        rc = client.getTorrent(url, :url)
        client.readTimeout = oldTimeout
        if ! rc
          rc = ["Downloading torrent failed: #{client.errorMsg}"]
        else
          if client.addTorrent(rc)
            rc = ["success"]
          else
            rc = ["Adding torrent failed: #{client.errorMsg}"]
          end
        end
      rescue
        rc = ["#{$!}. Please try again."]
      end
    else
      rc = ["The form submission didn't include the variable torrenturl"]
    end
    rc
  end
end

get "/#{$urlBasePath}download_magnet" do
  handleJSONRequest do |client|
    rc = []
    url = params[:magneturl]
    if url
      # Use a higher timeout here
      oldTimeout = client.readTimeout
      client.readTimeout = 12
      begin
        rc = client.getMagnet(url)
        client.readTimeout = oldTimeout
        if ! rc
          rc = ["Adding magnet URI failed: #{client.errorMsg}"]
        else
          rc = ["success"]
        end
      rescue
        rc = ["#{$!}. Please try again."]
      end
    else
      rc = ["The form submission didn't include the variable magneturl"]
    end
    rc
  end
end

# Handle an upload of a torrent file.
post "/#{$urlBasePath}upload_torrent" do
  # See http://www.wooptoot.com/file-upload-with-sinatra
  withAuthenticatedDaemonClient do |client|
    path = params['torrentfile'][:tempfile].path

    FileUtils.chmod 0644, path
    rc = client.getTorrent(path, :disk, params['torrentfile'][:filename])
    if ! rc
      "Uploading torrent failed: #{client.errorMsg}"
    else
      if client.addTorrent(rc)
        "Torrent file uploaded"
      else
        "Adding torrent failed: #{client.errorMsg}"
      end
    end
  end
end

get "/#{$urlBasePath}show_summary" do
  summaryHash = nil
  errorMessage = withAuthenticatedDaemonClient do |client|
    summaryHash = client.getTvShowSummary
    if ! summaryHash
      "Loading show summary failed: #{client.errorMsg}"
    else
      nil
    end
  end
  if errorMessage
    haml :show_summary, :locals => {:error => errorMessage}
  else
    haml :show_summary, :locals => {:summaryHash => summaryHash}
  end
end

get "/#{$urlBasePath}get_alarms" do
  handleJSONRequest do |client|
    rc = []
    alarms = client.getAlarms
    if ! alarms
      rc = ["Loading alarms failed: #{client.errorMsg}"]
    else
      rc = ["success"]
      # Convert the alarms to a hashtable for JSON
      alarms.each do |a|
        rc.push a.toHash
      end
    end
    rc
  end
end

# Class that acts as a Sinatra stream (has an 'each' method that returns
# blocks of the result), and that closes the client when the response is completed.
class FileDownloadStream
  def initialize(client, tcpStream)
    @client = client
    @tcpStream = tcpStream
  end
  
  def each
    @tcpStream.each do |s|
      yield s
    end
    @client.close
  end
end

get "/download_file" do
  path = params[:path]
  result = ""

  errorMessage = withAuthenticatedDaemonClient(false) do |client|
    mimeType = Mime.instance.getMimeTypeOfFilename(path)
    mimeType = "application/octet-stream" if ! mimeType

    headers "Content-Type" => mimeType

    tcpStreamHandler = client.prepareFileDownload(path)
    if tcpStreamHandler.recvLength
      headers "Content-Length" => tcpStreamHandler.recvLength.to_s
    else
      status 500
      puts "Error: retrieving file length failed" 
      break
    end
    
    result = FileDownloadStream.new(client, tcpStreamHandler)
    #result = tcpStreamHandler
    nil
  end

  if errorMessage
    status 500
    puts "Error: #{errorMessage}"
    break
  end 

  # Return a FileDownloadStream. Since this is an object that has the 'each' method, Sinatra
  # will call 'each' to build up the result, streaming it block by block.
  result
end

