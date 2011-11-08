require 'SyslogWrapper'
require 'DataPoint'
require 'fileutils'

class TestingRequestHandler < RequestHandler

  def initialize(terminateRequestHandler)
    super(terminateRequestHandler)
    # Setup some fake data.
    $testingTorrentList.addTorrent("[kat.ph]game.of.thrones.season.1.complete.hdtvrip.720p.x264.aac.ameet6.torrent")

    # Fake graph data.
    @dataPoints = []
    @dataPoints.push DataPoint.new(0, 0)
    @dataPoints.push DataPoint.new(1, 5)
    @dataPoints.push DataPoint.new(2, 20)
    @dataPoints.push DataPoint.new(3, 30)
    @dataPointsMutex = Mutex.new
    

    Thread.new{ 
      begin
        i = 4
        while @dataPoints.size < 100
          sleep 2
          @dataPointsMutex.synchronize{
            @dataPoints.push DataPoint.new(i,rand(50-28)+28)
          }
          i += 1
        end
      rescue
        puts $!
      end
    }
  end
  protected
  def handleListTorrentsRequest(req)
    resp = DaemonListTorrentsResponse.new
    $testingTorrentList.updateTorrents

    $testingTorrentList.torrents.each{ |i|
      if req.torrentId
        next if i[:name] != req.torrentId
      end

      info = TorrentInfo.new 

      req.dataToGet.each{ |d|
        if :name == d
          info.values[:name] = i[:name]
        elsif :creator == d
          info.values[:creator] = i[:creator]
        elsif :comment == d
          info.values[:comment] = i[:comment]
        elsif :total_size == d
          info.values[:total_size] = i[:total_size]
        elsif :piece_size == d
          info.values[:piece_size] = i[:piece_size]
        elsif :num_files == d
          info.values[:num_files] = i[:num_files]
        elsif :valid == d
          info.values[:valid] = i[:valid]
        elsif :state == d
          info.values[:state] = i[:state]
        elsif :progress == d
          info.values[:progress] = i[:progress]
        elsif :num_peers == d
          info.values[:num_peers] = i[:num_peers]
        elsif :download_rate == d
          info.values[:download_rate] = i[:download_rate]
        elsif :upload_rate == d
          info.values[:upload_rate] = i[:upload_rate]
        elsif :paused == d
          info.values[:paused] = (i[:paused]) ? "paused" : "running"
        end
      }

      resp.torrents.push info
    }
    resp
  end

  def handleAddTorrentsRequest(req)
    resp = DaemonAddTorrentResponse.new
    # Add this torrent to our fake list of torrents
    hash = { 
      :name => File.basename(req.filepath), 
      :creator => "Person",
      :total_size => 10000,
      :piece_size => 512,
      :num_files => 1,
      :valid => true,
      :state => :checking_files,
      :progress => 0.34,
      :num_peers => 34,
      :download_rate => 14.0,
      :upload_rate => 26.0
    }
    $testingTorrentList.torrents.push hash
    resp
  end

  def handleDelTorrentsRequest(req)
    resp = DaemonDelTorrentResponse.new
    $testingTorrentList.torrents.collect!{ |c|
      if c[:name] == req.torrentName
        nil
      else
        c
      end
    }
    $testingTorrentList.torrents.compact!
    resp
  end

  def handlePauseRequest(req)
    resp = DaemonPauseTorrentResponse.new
    $testingTorrentList.torrents.each{ |c|
      if c[:name] == req.torrentName
        c[:paused] = ! c[:paused]
      end
    }
    resp
  end

  def handleGetTorrentRequest(req)
    resp = DaemonGetTorrentResponse.new
    if req.filetype == :disk
      destpath = $config.torrentFileDir
      if req.finalFilename
        destpath += "/" + req.finalFilename
      end
      begin
        FileUtils.cp(req.sourcePath, destpath)
      rescue
        SyslogWrapper.instance.info "Error: handleGetTorrentRequest: Can't copy file '#{req.sourcePath}' to torrents dir: #{$!}"
        resp.successful = false
        resp.errorMsg = "Can't copy file '#{req.sourcePath}' to torrents dir: #{$!}"
        return resp
      end
      if req.finalFilename
        resp.path = destpath
      else
        resp.path = $config.torrentFileDir + "/" + File.basename(req.sourcePath)
      end
      if ! File.exists?(resp.path)
        resp.successful = false
        resp.errorMsg = "Copying file '#{req.sourcePath}' to torrents dir seemed to work, but the file '#{resp.path}' isn't there."
      end
    else
      begin
        filename = File.basename(f.base_uri.path)
        resp.path = $config.torrentFileDir + "/" + filename

        # Check if the file already exists and use that one. This is for the case where downloading a torrent takes a long
        # time and the client times out, but the backend finishes anyway
        return if File.exists?(resp.path)

        open(req.sourcePath) {|f|
          File.open(resp.path, "w"){ |outfile|
            outfile.write(f.read)
          }
          if ! File.exists?(resp.path)
            resp.successful = false
          end
        }
      rescue
        SyslogWrapper.instance.info "Error: handleGetTorrentRequest: Can't download URL '#{req.sourcePath}' to torrents dir: #{$!}"
        resp.successful = false
        resp.errorMsg = "Can't download URL '#{req.sourcePath}' to torrents dir: #{$!}"
      end
    end
    resp
  end

  def handleTerminateRequest(req)
    SyslogWrapper.instance.info "Terminating at user request."
    resp = DaemonTerminateResponse.new
    resp.successful = true
    terminate
    resp
  end

  def handleLoginRequest(req)
    resp = DaemonLoginResponse.new
    resp.successful = true
    resp.sid = "1234567890abcdefghijklmnop";
    resp
  end

  def handleLogoutRequest(req)
    resp = DaemonLogoutResponse.new
    resp
  end

  def handleAuthSessionRequest(req)
    resp = DaemonAuthSessionResponse.new
    resp.successful = true
    resp
  end

  def handleGetAlertsRequest(req)
    alerts = ["Couldn't connect to tracker or something","Bad encoding"]
    resp = DaemonGetAlertsResponse.new(alerts)
    resp
  end

  def handleFsInfoRequest(req)
    resp = DaemonFsInfoResponse.new
      resp.totalSpace = '100M'
      resp.usedSpace = '10M'
      resp.freeSpace = '90M'
      resp.usePercent = '10%'
    resp
  end

  def handleGraphInfoRequest(req)
    resp = DaemonGraphInfoResponse.new

    
    @dataPointsMutex.synchronize{
      resp.dataPoints = Array.new(@dataPoints)
    }

    resp
  end

  def handleListFilesRequest(req)
    resp = DaemonListFilesResponse.new
    resp.dir = "."
    resp.dir = Pathname.new(req.dir).realpath.to_s if req.dir
    
    Dir.new(resp.dir).each{ |file|
      if file != '.'
        info = FileInfo.createFrom(resp.dir, file)
        info.size = Formatter.formatSize(info.size)
        resp.files.push info
      end
    }

    # Sort the files so that directories are at the top, then files, and both are
    # sorted alphabetically.
    resp.files.sort!{ |a,b|
      ta = a.type == :dir ? 0 : 1
      tb = b.type == :dir ? 0 : 1

      rc = ta <=> tb
      if rc == 0
        rc = a.name.downcase <=> b.name.downcase
      end
      rc
    }  
  
    resp
  end

  # This method sends the file as a stream using the TcpStreamHandler 
  # on success. On error, a 0-length stream is sent.
  def handleDownloadFileRequest(req)
    begin
      length = File.size(req.path)
      # There is a possible race condition here. If we get the file size, and then
      # start sending bytes, and a writer is still writing to the end of the file
      # we will write too few bytes. As well if the file shrinks, we won't write enough
      # bytes and the reader will wait forever. Could solve this using a marker at the
      # end of the stream instead of prefixing with the length.
      io = File.open(req.path, "r")
      StreamMessage.new(length, io)
    rescue
      StreamMessage.new(0, nil)
    end
  end

  def handleDelFileRequest(req)
    resp = DaemonListFilesResponse.new
    # Make sure we don't download files outside of the data dir
      begin
        FileUtils.rm_r req.path
      rescue
        resp.successful = false
        resp.errorMsg = $!.to_s
      end
    resp
  end
end


