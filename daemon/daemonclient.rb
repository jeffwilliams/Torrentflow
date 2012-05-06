require 'torrentinfo'
require 'GenericTcpClient'
require 'GenericTcpMessageHandler'
require 'protocol'
require 'DataPoint'
require 'FileInfo'
require 'TcpStreamHandler'

class DaemonClient
  def initialize(addr, port, readTimeout = nil)
    @addr = addr
    @port = port
    @readTimeout = readTimeout
    connect(@addr, @port)
    @errorMsg = nil
  end

  attr_accessor :readTimeout

  def close
    if ! @clientSock.closed?
      @clientSock.close
    end
  end

  # Returns the error message for the last operation
  attr_reader :errorMsg
  
  # Returns an array of TorrentInfo objects 
  def listTorrents(attribsToGet = nil, torrentId = nil)
    attribsToGet = [:name, :creator, :progress] if ! attribsToGet

    req = DaemonListTorrentsRequest.new(attribsToGet, torrentId)
    sendAndRecv(req){ |resp|
      if resp.successful
        resp.torrents
      else
        nil
      end
    }
  end

  # Returns true on success, false on error
  def addTorrent(path)
    #path = File.expand_path(path)
    req = DaemonAddTorrentRequest.new(path)
    rc = false
    sendAndRecv(req){ |resp|
      if resp.successful
        rc = true
      end
    }
    rc
  end
  
  # Returns true if the torrent was deleted successfully.
  def delTorrent(name, deleteFiles = false)
    req = DaemonDelTorrentRequest.new(name, deleteFiles)
    sendAndRecv(req){ |resp|
      resp.successful
    }
  end

  # Get a torrent from disk or a URL and copy it to the torrents directory
  # Returns the destination path, or nil on failure.
  def getTorrent(path, type, finalFilename = nil)
    req = DaemonGetTorrentRequest.new(path, type, finalFilename)
    sendAndRecv(req){ |resp|
      if resp.successful
        resp.path 
      else
        nil
      end
    }
  end

  # Add the magnet URI to the session.
  def getMagnet(uri)
    req = DaemonGetMagnetRequest.new(uri)
    sendAndRecv(req){ |resp|
      if resp.successful
        true
      else
        nil
      end
    }
  end

  # Stop the torrent daemon. Returns true on success, or false on failure.
  def terminateDaemon
    req = DaemonTerminateRequest.new
    sendAndRecv(req){ |resp|
      resp.successful
    }
  end

  # Returns the sid of the user if the user succeeded in logging in, nil otherwise
  def login(user, pass)
    req = DaemonLoginRequest.new(user, pass)
    rc = nil
    sendAndRecv(req){ |resp|
      if resp.successful
        rc = resp.sid
      end
    } 
    rc
  end

  def logout(sid)
    req = DaemonLogoutRequest.new(sid)
    sendAndRecv(req){ |resp|
      resp.successful
    } 
  end

  # Returns true if the session is valid, false if the session is invalid or has expired
  def authSession(sid)
    req = DaemonAuthSessionRequest.new(sid)
    sendAndRecv(req){ |resp|
      resp.successful
    } 
  end

  def togglePaused(name)
    req = DaemonPauseTorrentRequest.new(name)
    sendAndRecv(req){ |resp|
      resp.successful
    } 
  end

  # If torrentName is specified, then only the alerts for that torrent
  # are returned. Otherwise the global list of alerts is returned.
  # Returns the array of alert messages on success, nil on failure
  def getAlerts(torrentName = nil)
    rc = nil
    req = DaemonGetAlertsRequest.new(torrentName)
    sendAndRecv(req){ |resp|
      if resp.successful
        rc = resp.alerts
      end
    } 
    rc
  end
  
  # Returns the DaemonFsInfoResponse object on success
  def getFsInfo
    req = DaemonFsInfoRequest.new
    rc = nil
    sendAndRecv(req){ |resp|
      rc = resp
    }
    rc
  end

  # Returns an array of DataPoint objects that represent the download rate at given times.
  def getGraphInfo(torrentId)
    req = DaemonGraphInfoRequest.new(torrentId)
    rc = nil
    sendAndRecv(req){ |resp|
      rc = resp.dataPoints
    }
    rc
  end

  # List the files in the specified subdirectory of the dataDir. Pass nil to 
  # get the contents of the dataDir itself.
  # Returns a DirContents object on success, or nil on failure.
  def listFiles(dir = nil)
    req = DaemonListFilesRequest.new(dir)
    sendAndRecv(req){ |resp|
      if resp.successful
        DirContents.new(resp.dir, resp.files)
      else
        nil
      end
    }
  end

  # Download a file from the daemon's data directory. This method
  # expects an IO object that is used as the destination of the file.
  # If a block is passed, the expected length of data is passed to the block.
  def downloadFile(path, destinationIO)
    req = DaemonDownloadFileRequest.new(path)

    rc = true
    @genericHandler.send req
    resp = @streamHandler.recv(destinationIO){ |length|
      if block_given?
        yield length
      end
    }
    if ! resp
      # Connection Failure! re-connect
      connect(@addr, @port)
      rc = false
    else
      rc = true
    end
    rc
  end

  # Delete a file from the daemon's data directory. 
  # Returns true if the deletion succeeded, false otherwise
  def delFile(path)
    req = DaemonDelFileRequest.new(path)
    sendAndRecv(req){ |resp|
      resp.successful
    }
  end

  # On success returns a hashtable; the key is the showname, and the value is a list 
  #   of ShowEpisodeRange objects (having startEpisode, endEpisode, and season properties)
  # On failure returns nil
  def getTvShowSummary
    req = DaemonGetTvShowSummaryRequest.new
    rc = nil
    sendAndRecv(req){ |resp|
      rc = resp.showRanges
    }
    rc
  end

  private
  def connect(addr, port)
    if @clientSock
      @clientSock.close
    end
    @clientSock = GenericTcpClient.new(addr, port, false).connect
    @genericHandler = GenericTcpMessageHandler.new(@clientSock)
    @streamHandler = TcpStreamHandler.new(@clientSock)
  end

  # Calls the attached block with the response if a response is successfully received. 
  # Returns false if there was no response. Returns the result of the block otherwise.
  def sendAndRecv(req)
    rc = true
    @genericHandler.send req
    begin
      resp = @genericHandler.recv(@readTimeout)
      if ! resp
        # Connection Failure! re-connect
        connect(@addr, @port)
        rc = false
      else 
        @errorMsg = resp.errorMsg
        rc = yield(resp)
      end
    rescue
      # Probably a timeout
      @errorMsg = $!.to_s
      rc = false
    end
    rc
  end
end
