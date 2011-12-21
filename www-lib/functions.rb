require 'daemonclient'
require 'config'
require 'SyslogWrapper'

SidCookieName = "rubytorrent_sid"

# Load the Config object.
# If there is an error loading the config file, it is yielded if a block was passed
def loadConfig
  config = nil
  configFile = Config.findConfigFile 
  if configFile
    config = Config.new
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

def sessionIsValid?(client, request)
  sid = request.cookies[SidCookieName]
  return false if !sid
  client.authSession(sid.value)
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

