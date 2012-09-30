require 'daemonclient'
require 'config'
require 'SyslogWrapper'
require 'json'

SidCookieName = "rubytorrent_sid"

# Load the Config object.
# If there is an error loading the config file, it is yielded if a block was passed
def loadConfig
  config = nil
  configFile = TorrentflowConfig.findConfigFile 
  if configFile
    config = TorrentflowConfig.new
    if ! config.load(configFile, true)
      yield "Daemon configuration file is invalid. See syslog for details" if block_given?
      config = nil
    end
  end
  config
end

# Returns the client on success, and nil on failure. Yields any error messages
# to the passed block.
def createDaemonClient
  client = nil

  port = 3000
  # Try and load the port from the config file
  config = loadConfig{ |errMsg| yield errMsg }
  if config
    port = config.listenPort
  end

  begin
    client = DaemonClient.new("localhost", port, 2)
  rescue
    yield "Connecting to torrent daemon on port #{port} failed: #{$!}"
  end
  client
end

# On success, yields the client, and returns nil. On failure, returns an error message. If the block
# yielded to returns a value, that is treated as the error message.
def withDaemonClient
  port = 3000
  # Try and load the port from the config file
  config = loadConfig{ |errMsg| yield errMsg }
  if config
    port = config.listenPort
  end
  
  begin
    client = DaemonClient.new("localhost", port, 2)
    err = yield client
    client.close
  rescue
    return "Connecting to torrent daemon on port #{port} failed: #{$!}"
  end
  err 
end

# On success, yields the client, and returns nil. On failure, returns an error message. If the block
# yielded to returns a value, that is treated as the error message.
def withAuthenticatedDaemonClient
  withDaemonClient do |client|
    if ! sessionIsValid?(client, session)
      "Your session has expired, or you need to log in"
    else
      yield client
    end
  end
end

def sessionIsValid?(client, sessionHolder)
  sid = nil
  if sessionHolder.is_a? Hash
    # Sinatra
    sid = sessionHolder[:rubytorrent_sid]
  else
    # eRuby
    sid = sessionHolder.cookies[SidCookieName].value
  end
  return false if !sid
  client.authSession(sid)
end

def handleLoginRequest(client, request)
  login = request.paramtable['login']
  pass = request.paramtable['password']
  login.untaint
  pass.untaint
  login(client, request, login.to_s, pass.to_s)
end

def login(client, request, user, password)
  sid = client.login(user, password)
  rc = false
  if sid
    # Login succeeded!
    cookie = Apache::Cookie.new(request)
    cookie.name = SidCookieName
    cookie.value = sid
    cookie.bake
    rc = true
  end
  rc
end

def handleLogoutRequest(client, request)
  sid = request.cookies[SidCookieName]
  return if !sid
  client.logout(sid.value) 
end

def getDownloadedFileNamesRecursively(client, dir = nil)
  contents = client.listFiles(dir)
  contents.files.each{ |elem|
    next if elem.name[0,1] == '.'
    if elem.type == :dir
      # Expand
      getDownloadedFileNamesRecursively(client, contents.dir + "/" + elem.name){ |f, d|
        yield f,d
      }
    elsif elem.type == :file
      yield elem.name, dir
    end
  }
end

# Attribs should be an array of symbols that represent the attributes that should
# be retrieved for the torrents. 
# sessionHolder should be set to Apache.request or Sinatra's session variable.
# Returns the value that should be sent in the http response body.
def handleGetTorrentsRequest(attribs, torrentNameFilter, sessionHolder)
  result = ""

  errorMessage = nil
  client = createDaemonClient{ |err|
    errorMessage = err
  }

  if client
    if ! sessionIsValid?(client, sessionHolder)
      client.close
      client = nil
      errorMessage = "Your session has expired, or you need to log in"
    end
  end

  if client
    torrents = client.listTorrents(attribs, torrentNameFilter)
    if torrents 
      # Send the array of TorrentInfo objects as JSON
      encoded = torrents.collect{ |t|
        t.values
      }
      rc = ["success"]
      rc.concat encoded
      result = JSON.generate(rc)
    end 
    client.close
  else 
    result = JSON.generate([errorMessage])
  end

  result
end
