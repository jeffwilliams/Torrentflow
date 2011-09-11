require 'daemonclient'
require 'config'

SidCookieName = "rubytorrent_sid"

# Returns the client on success, and nil on failure. Yields any error messages
# to the passed block.
def createDaemonClient
  client = nil

  port = 3000
  # Try and load the port from the config file
  configFile = Config.findConfigFile
  if configFile
    config = Config.new
    if config.load(configFile, true)
      port = config.listenPort
    else
      yield "Daemon configuration file is invalid. See syslog for details"
      return nil
    end
  end

  begin
    client = DaemonClient.new("localhost", port, 2)
  rescue
    yield "Connecting to torrent daemon on port #{port} failed: #{$!}"
  end
  client
end

def calculateRemainingTime(torrentInfo)
  "1h"
end

# This function processes the request from Apache.request
# assuming it's a modification request (submitted by the form
# who's action is modify_torrents)
#
# This function returns the empty string on success, and an error string on failure,
def handleModificationRequest(request)
  operation = nil
  if request.paramtable['remove_torrent']
    operation = :remove_torrent
  elsif request.paramtable['remove_files']
    operation = :remove_files
  elsif request.paramtable['pause']
    operation = :pause
  else
    return "Unknown operation from form with action 'modify_torrents'"
  end
  
  torrentlist = []
  request.paramtable.each{ |k,v|
    if k =~ /^check/
      v.untaint
      torrentlist.push v.to_s
    end
  }
  errorMessage = nil
  client = createDaemonClient{ |err|
    errorMessage = err
  }
  if client
    if operation == :remove_torrent
      torrentlist.each{ |t|
        client.delTorrent(t)
      }
    elsif operation == :remove_files
      torrentlist.each{ |t|
        client.delTorrent(t, true)
      }
    elsif operation == :pause
      torrentlist.each{ |t|
        client.togglePaused(t)
      }
    end
    client.close
    return ""
  else
    return errorMessage
  end
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
