require 'protocol'
require 'torrentinfo'
require 'fileutils'
require 'open-uri'
require 'TestingTorrentList'
require '../mylibtorrent/libtorrent'
require 'Authentication'
require 'Formatter'
require 'TimeSampleHolder'
require 'DataPoint'
require 'SyslogWrapper'
require 'pathname'
require 'FileInfo'
require 'TcpStreamHandler'
require 'ShowNameParse'
require 'UsageTracker'

# Load Mongo if it's installed. 
$haveMongo = true
begin
  require 'rubygems'
  require 'mongo'
rescue LoadError
  $haveMongo = false
end

class StreamMessage
  def initialize(len, io)
    @io = io
    @len = len
  end

  attr_accessor :io
  attr_accessor :len
end

# This class is used to manage a single client socket. It waits for requests and 
# sends back responses.
class RequestHandler
  def initialize(terminateRequestHandler)
    @done = false
    @terminateRequestHandler = terminateRequestHandler
    @cachedDf = nil
    @cachedDfTimeout = nil
  end
  
  def manage(sock, addr, port)
    genericHandler = GenericTcpMessageHandler.new(sock)
    streamHandler = TcpStreamHandler.new(sock)
    while ! @done  
      req = genericHandler.recv
      if ! req
        sock.close
        break
      end
      resp = handle(req)
      if resp
        if resp.is_a? StreamMessage
          streamHandler.send resp.len, resp.io
          resp.io.close if resp.io && ! resp.io.closed?
        else
          genericHandler.send resp
        end
      end
    end
    if ! @done
      #SyslogWrapper.info "Client #{addr}:#{port} disconnected. Closing socket."
    end
  end

  # Returns a response to send
  def handle(req)
    if req.is_a? DaemonListTorrentsRequest
      handleListTorrentsRequest req
    elsif req.is_a? DaemonAddTorrentRequest
      handleAddTorrentsRequest req
    elsif req.is_a? DaemonDelTorrentRequest
      handleDelTorrentsRequest req
    elsif req.is_a? DaemonGetTorrentRequest
      handleGetTorrentRequest req
    elsif req.is_a? DaemonTerminateRequest
      handleTerminateRequest req
    elsif req.is_a? DaemonLoginRequest
      handleLoginRequest req
    elsif req.is_a? DaemonAuthSessionRequest
      handleAuthSessionRequest req
    elsif req.is_a? DaemonLogoutRequest
      handleLogoutRequest req
    elsif req.is_a? DaemonPauseTorrentRequest
      handlePauseRequest req
    elsif req.is_a? DaemonGetAlertsRequest
      handleGetAlertsRequest req
    elsif req.is_a? DaemonFsInfoRequest
      handleFsInfoRequest req
    elsif req.is_a? DaemonGraphInfoRequest
      handleGraphInfoRequest req
    elsif req.is_a? DaemonListFilesRequest
      handleListFilesRequest req
    elsif req.is_a? DaemonDownloadFileRequest
      handleDownloadFileRequest req
    elsif req.is_a? DaemonDelFileRequest
      handleDelFileRequest req
    elsif req.is_a? DaemonGetTvShowSummaryRequest
      handleGetTvShowSummaryResponse req
    elsif req.is_a? DaemonGetMagnetRequest
      handleGetMagnetRequest req
    elsif req.is_a? DaemonGetUsageRequest
      handleGetUsageRequest req
    else
      SyslogWrapper.info "Got an unknown request type #{req.class}"
      nil
    end
  end

  def terminate
    @done = true
    @terminateRequestHandler.call
  end

  protected
  def handleListTorrentsRequest(req)
    raise "Override this method"
  end
  def handleAddTorrentsRequest(req)
    raise "Override this method"
  end
  def handleDelTorrentsRequest(req)
    raise "Override this method"
  end
  def handleGetTorrentRequest(req)
    raise "Override this method"
  end
  def handleTerminateRequest(req)
    raise "Override this method"
  end
  def handleLoginRequest(req)
    raise "Override this method"
  end
  def handleLogoutRequest(req)
    raise "Override this method"
  end
  def handleAuthSessionRequest(req)
    raise "Override this method"
  end
  def handlePauseRequest(req)
    raise "Override this method"
  end
  def handleGetAlertsRequest(req)
    raise "Override this method"
  end
  def handleFsInfoRequest(req)
    raise "Override this method"
  end
  def handleGraphInfoRequest(req)
    raise "Override this method"
  end
  def handleListFilesRequest(req)
    raise "Override this method"
  end
  def handleDelFileRequest(req)
    raise "Override this method"
  end
  def handleGetTvShowSummaryResponse(req)
    raise "Override this method"
  end
  def handleGetMagnetRequest(req)
    raise "Override this method"
  end
end

class RubyTorrentInfo
  # Max datapoints stored per torrent
  MaxDataPoints = 100
  def initialize
    @torrentFileName = nil
    avgProc = Proc.new{ |a,b|
      DataPoint.new( (a.x + b.x)/2, (a.y + b.y)/2 )
    }
    @downloadRateDataPoints = TimeSampleHolder.new(MaxDataPoints, avgProc)
    @graphDataThread = nil
    @seedingStopThread = nil
  end
  # Name of the .torrent file
  attr_accessor :torrentFileName
  # A TimeSampleHolder that contains DataPoint objects for the download rate at a given time
  attr_accessor :downloadRateDataPoints
  # The thread getting sample data points
  attr_accessor :graphDataThread

  def startGraphDataThread(torrentHandle)
    if ! @graphDataThread
      @graphDataThread = GraphDataThread.new(torrentHandle, @downloadRateDataPoints)
      @graphDataThread.run
    end
  end
  def stopGraphDataThread
    if  @graphDataThread
      @graphDataThread.kill
    end
  end
  def startSeedingStopThread(torrentHandle)
    if ! @seedingStopThread
      @seedingStopThread = SeedingStopThread.new(torrentHandle, $config.seedingTime)
      @seedingStopThread.run
    end
  end
  def stopSeedingStopThread
    if  @seedingStopThread
      @seedingStopThread.kill
    end
  end
end

class BackgroundThread
  def initialize
    @done = false
  end

  def run
    Thread.new{ 
      begin
        work
      rescue
        SyslogWrapper.info "[Thread #{self.object_id}] Caught an unhandled exception in #{self.class.name} thread: #{$!}"
      end
      SyslogWrapper.info "[Thread #{self.object_id}] Thread terminating"
    }
  end 

  def kill
    @done = true
  end

  private
  def work
  end
end

class TorrentHandleBackgroundThread < BackgroundThread
  def initialize(handle)
    @handle = handle
    super()
  end

  attr_accessor :handle

  def torrentIsRunning
    (@handle.status.state == Libtorrent::TorrentStatus::DOWNLOADING_METADATA ||
      @handle.status.state == Libtorrent::TorrentStatus::DOWNLOADING) &&
      ! @handle.paused?
  end
end

#
# This class measures the download rate periodically in KiloBytes/s
class GraphDataThread < TorrentHandleBackgroundThread
  def initialize(handle, timeSampleHolder)
    super(handle)
    @timeSampleHolder = timeSampleHolder
    @timeSampleHolderMutex = Mutex.new
  end
  
  attr_reader :timeSampleHolderMutex
  
  def work
    begin
      startTime = Time.new
      while ! @done

        # Only add the sample if the torrent is running
        if torrentIsRunning
          @timeSampleHolderMutex.synchronize{
            @timeSampleHolder.addSample DataPoint.new( (Time.new - startTime) / 60, (@handle.status.download_rate.to_f/1024))
          }
        end
        sleep 5
      end
    rescue
      SyslogWrapper.info "Exception in graph data thread: #{$!}"
    end    
  end
end

# One of these objects is created per torrent, and it starts a new thread that stops
# us from seeding after a period of time has elapsed.
class SeedingStopThread < TorrentHandleBackgroundThread
  def initialize(handle, maxUploadSeconds)
    super(handle)
    @maxUploadSeconds = maxUploadSeconds
  end
  
  def work
    begin

      SyslogWrapper.info "[Thread #{self.object_id}] Started monitoring time seeding for #{@handle.name} "
      @done = false
      startTime = Time.new
      while ! @done

        # Only add the sample if the torrent is running
        if @handle.status.state == Libtorrent::TorrentStatus::SEEDING
          seconds = getTimeSeeding
          if seconds && seconds  > @maxUploadSeconds
            SyslogWrapper.info "[Thread #{self.object_id}] The torrent #{@handle.name} has been seeding for #{seconds} seconds, which is more than #{@maxUploadSeconds}. stopping seeding."
            if @handle.respond_to?(:auto_managed=)
              @handle.auto_managed = false
            else
              SyslogWrapper.info "Can't un-auto-manage torrent since the version of libtorrent is too old"
            end
            @handle.pause
            @done = true
          end
        end
        sleep 10
      end
    rescue
      SyslogWrapper.info "[Thread #{self.object_id}] Got exception when monitoring time seeding for #{@handle.name}"
      SyslogWrapper.info "[Thread #{self.object_id}] Exception: #{$!}"
      puts "Exception in seeding monitoring thread: #{$!}"
    end
    SyslogWrapper.info "[Thread #{self.object_id}] Thread monitoring time seeding for #{@handle.name} exiting."
  end

  def getTimeSeeding
    # Get the latest modification date on the files in the torrent being downloaded, 
    newest = nil
    @handle.info.files.each{ |file|
      path = $config.dataDir + "/" + file
      if path && File.exists?(path)
        newest = File.mtime(path)
      end
    }
    if !newest
      SyslogWrapper.info "Warning: The torrent #{@handle.name} is seeding, but has no files in the data dir"
      nil
    else
      Time.new - newest
    end
  end

end

class UsageTrackingBackgroundThread < BackgroundThread
  def initialize(session, mongoDb)
    @session = session
    resetDay = $config.usageMonthlyResetDay
    if ! resetDay
      SyslogWrapper.info "Usage tracking is enabled, but the monthly reset day was not specified. Defaulting to the 1st of the month."
      resetDay = 1
    end
    if ! mongoDb
      SyslogWrapper.info "No Mongo connection; tracked usage won't be persistent across torrentflow restarts."
      SyslogWrapper.info "This means a restart will cause limit enforcement to fail."
    end
    @usageTracker = UsageTracker.new(resetDay, mongoDb)
    @mutex = Mutex.new
    super()
  end
  
  attr_accessor :mutex

  def work
    SyslogWrapper.info "Starting the usage tracking thread."
    while
      begin
        @mutex.synchronize {
          @usageTracker.update(@session.status.total_download + @session.status.total_upload)
        }
      rescue
        SyslogWrapper.info "Usage tracking thread got an exception: #{$!}."
      end
      sleep 10
    end
  end

  def withUsageTracker
    @mutex.synchronize do
      yield @usageTracker
    end
  end
end

# A class for getting temporary names that are unique with regards to the currently 
# outstanding names.
class TemporaryNameManager
  def initialize(prefix)
    @names = {}
    @prefix = prefix
    @nextOrd = 1
    @freeNames = []
  end

  def newName
    if @freeNames.size > 0
      @freeNames.shift
    else
      rc = @prefix + @nextOrd.to_s
      @nextOrd += 1
      @names[rc] = 1
      rc
    end
  end

  def freeName(name)
    if @names.has_key?(name)
      @names.delete name
      @freeNames.push name
    end
  end
end

class NullTorrentInfo
  def creator
    ""
  end
  def comment
    ""
  end
  def total_size
    0
  end
  def piece_length
    0
  end
  def num_files
    0
  end
  def valid?
    true
  end
end

# An implementation of RequestHandler that uses the Rasterbar libtorrent library for 
# handling torrents.
class RasterbarLibtorrentRequestHandler < RequestHandler

  def initialize(terminateRequestHandler)
    super(terminateRequestHandler)

    # Maps the name of the torrent (from torrent_info) to our own RubyTorrentInfo object that contains
    # extra information about the torrent not stored by libtorrent
    @torrentInfo = {}
    @session = Libtorrent::Session.new
    @session.listen_on($config.torrentPortLow, $config.torrentPortLow)

    # Set up the encryption settings
    peSettings = Libtorrent::PeSettings.new
    peSettings.out_enc_policy = convertEncPolicy($config.outEncPolicy)
    peSettings.in_enc_policy = convertEncPolicy($config.inEncPolicy)
    peSettings.allowed_enc_level = convertEncLevel($config.allowedEncLevel)
    @session.set_pe_settings(peSettings)

    # Get a list of all the torrents from the torrent directory and add them
    Dir.new($config.torrentFileDir).each{ |file|
      if file != '.' && file != '..'
        path = "#{$config.torrentFileDir}/#{file}"
        next if ! File.file?(path)
        begin
          loadAndAddTorrent(path, file)
        rescue
          SyslogWrapper.info "Failed to load #{path}: it is not a valid torrent: #{$!}"
        end
      end
    }
    @authentication = Authentication.new
    # Alerts that aren't specific to a torrent
    @globalAlerts = []
    # Alerts specific to a torrent. Indexed by torrent name
    @torrentAlerts = {}
    # Class used to get names for Magnet links while they are downloading their metainfo
    @magnetTempNameMgr = TemporaryNameManager.new("Magnet Link ")
    # Empty torrent info object used when the torrent handle hasn't downloaded metadata yet but we must 
    # display the torrent
    @nullTorrentInfo = NullTorrentInfo.new

    # Connect to Mongo if it's available
    if $haveMongo && $config.mongoDb
      SyslogWrapper.info "Connecting to mongo"
      # Connection.new accepts nil arguments for host and port
      begin
        @mongoConnection = Mongo::Connection.new($config.mongoHost, $config.mongoPort)
        @mongoDb = @mongoConnection.db($config.mongoDb)
        if $config.mongoUser
          if ! @mongoDb.authenticate($config.mongoUser, $config.mongoPass)
            SyslogWrapper.info "Authenticating to Mongo failed: #{$!}"
            @mongoConnection = nil
            @mongoDb = nil
          end
        end
      rescue
        SyslogWrapper.info "Connecting to Mongo failed: #{$!}"
        @mongoConnection = nil
      end
    end

    @usageTrackingThread = nil
    if $config.enableUsageTracking
      @usageTrackingThread = UsageTrackingBackgroundThread.new(@session, @mongoDb)
      @usageTrackingThread.run 
    end
  end

  protected
  def handleListTorrentsRequest(req)
    resp = DaemonListTorrentsResponse.new

    torrentHandles = @session.torrents

    torrentHandles.each{ |handle|
      next if ! handle.valid?
      handleInfo = nil
      if handle.has_metadata
        handleInfo = handle.info
      else
        handleInfo = NullTorrentInfo.new
      end

      if req.torrentId
        next if req.torrentId != handle.name
      end

      info = TorrentInfo.new 

      req.dataToGet.each{ |d|
        if :name == d
          info.values[:name] = handle.name
        elsif :creator == d
          info.values[:creator] = handleInfo.creator
        elsif :comment == d
          info.values[:comment] = handleInfo.comment
        elsif :total_size == d
          info.values[:total_size] = Formatter.formatSize(handleInfo.total_size)
        elsif :piece_size == d
          info.values[:piece_size] = Formatter.formatSize(handleInfo.piece_length)
        elsif :num_files == d
          info.values[:num_files] = handleInfo.num_files
        elsif :valid == d
          info.values[:valid] = handleInfo.valid?
        elsif :state == d
          info.values[:state] = stateToSym(handle.status.state)
        elsif :paused == d
          info.values[:paused] = (handle.paused?) ? "paused" : "running"
        elsif :progress == d
          info.values[:progress] = Formatter.formatPercent(handle.status.progress)
        elsif :num_peers == d
          info.values[:num_peers] = handle.status.num_peers
        elsif :download_rate == d
          info.values[:download_rate] = Formatter.formatSpeed(handle.status.download_rate)
        elsif :upload_rate == d
          info.values[:upload_rate] = Formatter.formatSpeed(handle.status.upload_rate)
        elsif :estimated_time == d
          info.values[:estimated_time] = calcEstimatedTime(handle)
        elsif :upload_limit == d
          info.values[:upload_limit] = Formatter.formatSpeed(handle.upload_rate_limit)
        elsif :download_limit == d
          info.values[:download_limit] = Formatter.formatSpeed(handle.download_rate_limit)
        elsif :ratio == d
          info.values[:ratio ] = $config.ratio
        elsif :max_connections == d
          info.values[:max_connections] = $config.maxConnectionsPerTorrent
        elsif :max_uploads == d
          info.values[:max_uploads] = $config.maxUploadsPerTorrent
        end
      }

      resp.torrents.push info
    }
    resp   
  end

  def handleAddTorrentsRequest(req)
    resp = DaemonAddTorrentResponse.new
    # Add this torrent which exists in the torrentsdir to our session
    if File.exists? req.filepath
      begin
        loadAndAddTorrent(req.filepath, File.basename(req.filepath)){ |existingTorrentInfo|
          resp.successful = false
          resp.errorMsg = "The torrent is already being downloaded as '#{existingTorrentInfo.name}'"
        }
      rescue
        resp.successful = false
        resp.errorMsg = $!.to_s
      end
    else
      resp.successful = false
      resp.errorMsg = "The torrent file doesn't exist: #{req.filepath}"
    end
    resp
  end

  def handleGetMagnetRequest(req)
    begin
      resp = DaemonGetMagnetResponse.new
      # Add this magnet uri to the session
      tempName = @magnetTempNameMgr.newName
      handle = Libtorrent::add_magnet_uri(@session, req.sourcePath, $config.dataDir, tempName)
      if ! handle.valid?
        SyslogWrapper.info "handleGetMagnetRequest: handle returned is invalid"
        resp.successful = false
        resp.errorMsg = "Invalid magnet link"
      else
        # We need to wait until metadata is downloaded before using the torrent handle.
        Thread.new{
          tries = 600
          while ! handle.has_metadata && tries > 0
            sleep 1
            tries -= 1
          end
          if ! handle.has_metadata
            SyslogWrapper.info "handleGetMagnetRequest: Could never get metadata for magnet link #{tempName} ('#{req.sourcePath}'). Removing torrent."
            @session.remove_torrent(handle, Libtorrent::Session::DELETE_FILES)
          else
            adjustTorrentHandle(handle, handle.info, "Magnet File")
          end
          @magnetTempNameMgr.freeName(tempName)
        }
      end
      SyslogWrapper.info "handleGetMagnetRequest: Add completed"
    rescue
      resp.successful = false
      resp.errorMsg = $!.to_s
    end
    resp
  end

  def handleDelTorrentsRequest(req)
    resp = DaemonDelTorrentResponse.new
    i = findTorrentHandle(req.torrentName)
    if ! i
      resp.successful = false
      resp.errorMsg = "No such torrent"
      return resp
    end
    if i.name == req.torrentName
      torrentName = i.name
      if req.deleteFiles
        @session.remove_torrent(i, Libtorrent::Session::DELETE_FILES)
      else
        @session.remove_torrent(i, Libtorrent::Session::NONE)
      end

      # Remove the .torrent file
      info = @torrentInfo[torrentName] 
      if info && info.torrentFileName 
        path = "#{$config.torrentFileDir}/#{info.torrentFileName}"
        begin
          FileUtils.rm path
        rescue
          resp.successful = true
          resp.errorMsg = "Deleting torrent file failed: #{$!}"
        end
        info.stopGraphDataThread
        info.stopSeedingStopThread
        @torrentInfo.delete torrentName
      end
    end

    if @torrentAlerts.has_key?(req.torrentName)
      @torrentAlerts.delete req.torrentName
    end
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
        SyslogWrapper.info "Error: handleGetTorrentRequest: Can't copy file '#{req.sourcePath}' to torrents dir: #{$!}"
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
        # open-uri doesn't handle [ and ] properly
        encodedSourcePath = URI.escape(req.sourcePath, /[\[\]]/)

        open(encodedSourcePath) {|f|
          filename = File.basename(f.base_uri.path)
          resp.path = $config.torrentFileDir + "/" + filename
          File.open(resp.path, "w"){ |outfile|
            outfile.write(f.read)
          }
          if ! File.exists?(resp.path)
            resp.successful = false
          end
        }
      rescue
        SyslogWrapper.info "Error: handleGetTorrentRequest: Can't download URL '#{req.sourcePath}' to torrents dir: #{$!}"
        resp.successful = false
        resp.errorMsg = "Can't download URL '#{req.sourcePath}' to torrents dir: #{$!}"
      end
    end
    resp
  end

  def handleTerminateRequest(req)
    SyslogWrapper.info "Terminating at user request."
    resp = DaemonTerminateResponse.new
    resp.successful = true
    terminate
    resp
  end

  def handleLoginRequest(req)
    resp = DaemonLoginResponse.new
    resp.successful = @authentication.authorize(req.login, req.password)
    if resp.successful
      sid = @authentication.startSession(req.login)
      if sid
        resp.sid = sid
      else
        resp.successful = false
      end
    end
    resp
  end

  def handleLogoutRequest(req)
    resp = DaemonLogoutResponse.new
    @authentication.endSession(req.sid)
    resp
  end

  def handleAuthSessionRequest(req)
    resp = DaemonAuthSessionResponse.new
    resp.successful = @authentication.validSession?(req.sid)
    resp
  end

  def handlePauseRequest(req)
    resp = DaemonPauseTorrentResponse.new
    handle = findTorrentHandle(req.torrentName)
    return resp if ! handle

    if handle.paused?
      if handle.respond_to?(:auto_managed=)
        handle.auto_managed = true
      end
      handle.resume
    else
      if handle.respond_to?(:auto_managed=)
        handle.auto_managed = false
      end
      handle.pause
    end
    resp
  end

  def handleGetAlertsRequest(req)
    processNewAlerts

    list = nil
    if ! req.torrentName
      list = @globalAlerts
    else
      list = @torrentAlerts[req.torrentName]
      list = [] if ! list
    end

    alerts = []
    list.each{ |alert|
      if alert.respond_to?(:message)
        alerts.push alert.message.to_s
      else
        alerts.push alert.msg.to_s
      end
    }
    resp = DaemonGetAlertsResponse.new(alerts)
    resp
  end

  def handleFsInfoRequest(req)
    resp = DaemonFsInfoResponse.new
    # Cache the output of df -h, just in case it is network storage.
    if ( ! @cachedDf || (@cachedDfTimeout && @cachedDfTimeout < Time.new))
      @cachedDf = `df -h #{$config.dataDir}`
      @cachedDfTimeout = Time.new + 20
    end

    #output = `df -h #{$config.dataDir}`
    output = @cachedDf
    #Filesystem            Size  Used Avail Use% Mounted on
    #//storage/movies      928G  106G  823G  12% /media/movies
    # Ignore header line
    lines = output.split($/)
    lines.shift
    if lines[0] =~ /^[^ ]+\s+([^ ]+)\s+([^ ]+)\s+([^ ]+)\s+([^ ]+)/
      resp.totalSpace = $1
      resp.usedSpace = $2
      resp.freeSpace = $3
      resp.usePercent = $4
    end

    resp
  end

  def handleGraphInfoRequest(req)
    resp = DaemonGraphInfoResponse.new
    info = @torrentInfo[req.torrentId] 
    if ! info
      resp.successful = false
      resp.errorMsg = "No torrent info for '#{req.torrentId}'"
      return resp
    end

    data = []
    if info.graphDataThread
      info.graphDataThread.timeSampleHolderMutex.synchronize{ 
        data = info.downloadRateDataPoints.samples
      
      }
    else
      data = info.downloadRateDataPoints.samples
    end
    resp.dataPoints = data

    resp
  end

  def handleListFilesRequest(req)
    resp = DaemonListFilesResponse.new
    absDataDir = Pathname.new($config.dataDir).realpath.to_s
    # If the dir specified is nil, then assume the request is for the datadir.
    if ! req.dir
      absRequestedDir = absDataDir
    else
      if ! File.exists?(req.dir)
        resp.successful = false
        resp.errorMsg = "The directory #{absRequestedDir} doesn't exist"
        return resp
      end
      absRequestedDir = Pathname.new(req.dir).realpath.to_s
      # Don't allow listing of directories above datadir
      absRequestedDir = absDataDir if absRequestedDir !~ /^#{absDataDir}/
    end

    resp.dir = absRequestedDir
    Dir.new(absRequestedDir).each{ |file|
      if file != '.'
        info = FileInfo.createFrom(absRequestedDir, file)
        info.size = Formatter.formatSize(info.size)
        resp.files.push info
      end
    }

    if absRequestedDir == absDataDir
      resp.files.collect!{ |f|
        if f.name != ".."
          f
        else
          nil
        end
      }
      resp.files.compact!
    end
  
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
      # Make sure we don't download files outside of the data dir
      return StreamMessage.new(0, nil) if ! pathIsUnderDataDir(req.path)

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
    if pathIsUnderDataDir req.path
      begin
        FileUtils.rm_r req.path
      rescue
        resp.successful = false
        resp.errorMsg = $!.to_s
      end
    else
      resp.successful = false
      resp.errorMsg = "Access is denied for the directory '#{req.path}'"
    end
    resp
  end

  def handleGetTvShowSummaryResponse(req)
    resp = DaemonGetTvShowSummaryResponse.new

    interp = ShowNameInterpreter.new
    filesUnder($config.dataDir){ |e, dir|
      interp.addName(e, FilenameMetaInfo.new.setParentDir(dir))
    }
    shows = interp.processNames
    shows.each{ |k,v|
      resp.showRanges[k] = v.episodeRanges
    }
    
    resp
  end

  def handleGetUsageRequest(req)
    resp = DaemonGetUsageResponse.new
    if ! $config.enableUsageTracking
      resp.successful = false
      resp.errorMsg = "Usage tracking is not enabled."
    elsif ! @usageTrackingThread
      resp.successful = false
      resp.errorMsg = "Usage tracking is enabled, but the usage tracking thread is not running. Check the log for errors."
    elsif req.type != :daily && req.type != :monthly
      resp.successful = false
      resp.errorMsg = "Unsupported usage tracking period type #{req.type}"
    elsif req.qty != :current && req.qty != :all
      resp.successful = false
      resp.errorMsg = "Unsupported usage tracking quantity #{req.qty}"
    else
      @usageTrackingThread.withUsageTracker do |tracker|
        # Build an array of hashes to return
        buckets = nil
        if req.qty == :current
          buckets = [tracker.currentUsage(req.type)]
        else
          buckets = tracker.allUsage(req.type)
            #new.value = Formatter.formatSize(new.value)
        end
        resp.buckets = buckets.collect do |bucket|
          {"label" => bucket.label, "value" => Formatter.formatSize(bucket.value)}
        end
      end
    end
    resp
  end

  private

  def stateToSym(state)
    if state == Libtorrent::TorrentStatus::QUEUED_FOR_CHECKING
      :queued_for_checking
    elsif state == Libtorrent::TorrentStatus::CHECKING_FILES
      :checking_files
    elsif defined?(Libtorrent::TorrentStatus::CONNECTING_TO_TRACKER) && state == Libtorrent::TorrentStatus::CONNECTING_TO_TRACKER
      :connecting_to_tracker
    elsif state == Libtorrent::TorrentStatus::DOWNLOADING_METADATA
      :downloading_metadata
    elsif state == Libtorrent::TorrentStatus::DOWNLOADING
      :downloading
    elsif state == Libtorrent::TorrentStatus::FINISHED
      :finished
    elsif state == Libtorrent::TorrentStatus::SEEDING
      :seeding
    elsif state == Libtorrent::TorrentStatus::ALLOCATING
      :allocating
    elsif defined?(Libtorrent::TorrentStatus::CHECKING_RESUME_DATA) && state == Libtorrent::TorrentStatus::CHECKING_RESUME_DATA
      :checking_resume_data
    else
      :unknown
    end
  end

  def calcEstimatedTime(torrentHandle)
    # Time left = amount_left / download_rate
    #           = total_size * (1-progress) / download_rate
    if torrentHandle.has_metadata && torrentHandle.status.download_rate.to_f > 0
      secondsLeft = torrentHandle.info.total_size.to_f * (1 - torrentHandle.status.progress.to_f) / torrentHandle.status.download_rate.to_f
      Formatter.formatTime(secondsLeft)
    else
      "unknown"
    end
  end

  def findTorrentHandle(torrentName)
    torrentHandles = @session.torrents
    torrentHandles.each{ |i|
      if i.name == torrentName
        return i
      end
    }
    nil
  end

  # Read the alerts that libtorrent has pending, and store them
  # in the correct member variable. Torrent-specific alerts are stored
  # in the @torrentAlerts hash, and non-specific ones are stored int he 
  # @globalAlerts list
  def processNewAlerts
    @session.alerts.each{ |alert|
      if alert.is_a? Libtorrent::TorrentAlert
       addToHashList @torrentAlerts, alert.handle.name, alert
      else
        @globalAlerts.push alert
        # For now since nothing is reading the alerts, just store a max of 
        # 5.
        @globalAlerts.shift if @globalAlerts.length > 5
      end
    }
  end
  
  def addToHashList(hash, key, value)
    if hash.has_key?(key)
      hash[key].push value
    else
      hash[key] = [value]
    end
  end
  
  def convertEncPolicy(level)
    if level == :forced
      Libtorrent::PeSettings::FORCED
    elsif level == :enabled
      Libtorrent::PeSettings::ENABLED
    elsif level == :disabled
      Libtorrent::PeSettings::DISABLED
    else
      Libtorrent::PeSettings::ENABLED
    end
  end

  def convertEncLevel(level)
    if level == :plaintext
      Libtorrent::PeSettings::PLAINTEXT
    elsif level == :rc4
      Libtorrent::PeSettings::RC4
    elsif level == :both
      Libtorrent::PeSettings::BOTH
    else
      Libtorrent::PeSettings::BOTH
    end
  end

  def encPolicyToSym(level)
    if level == Libtorrent::PeSettings::FORCED
      :forced
    elsif level == Libtorrent::PeSettings::ENABLED
      :enabled
    elsif level == Libtorrent::PeSettings::DISABLED
      :disabled
    else
      :unknown
    end
  end

  def encLevelToSym(level)
    if level == Libtorrent::PeSettings::PLAINTEXT
      :plaintext
    elsif level == Libtorrent::PeSettings::RC4
      :rc4
    elsif level == Libtorrent::PeSettings::BOTH
      :both
    else
      :unknown
    end
  end

  # Load a torrent and add it to the session. Filename should be the basename of the torrent file.
  # Returns true on success, false if the torrent was already added. If the torrent was already 
  #   added and a block is passed, the torrent info of the existing torrent is passed to the block.
  # Probably throws exceptions also.
  def loadAndAddTorrent(path, filename)
    begin
      torrentInfo = Libtorrent::TorrentInfo::load(path)
      # Make sure the torrent doesn't already exist in the session or libtorrent
      # will abort()
      handle = @session.find_torrent(torrentInfo.info_hash)
      if ! handle.valid? 
        handle = @session.add_torrent(torrentInfo, $config.dataDir);
        adjustTorrentHandle(handle, torrentInfo, filename)
        true
      else
        yield torrentInfo if block_given?
        false
      end
    rescue
      SyslogWrapper.info("loadAndAddTorrent: Exception adding torrent: #{$!}")
      raise $!
    end
  end

  def adjustTorrentHandle(handle, torrentInfo, filename)
    info = RubyTorrentInfo.new
    info.torrentFileName = filename
    info.startGraphDataThread(handle)
    info.startSeedingStopThread(handle)
    @torrentInfo[torrentInfo.name] = info
    handle.ratio = $config.ratio
    handle.max_connections = $config.maxConnectionsPerTorrent if $config.maxConnectionsPerTorrent
    handle.max_uploads = $config.maxUploadsPerTorrent if $config.maxUploadsPerTorrent
    handle.download_rate_limit = $config.downloadRateLimitPerTorrent if $config.downloadRateLimitPerTorrent
    handle.upload_rate_limit = $config.uploadRateLimitPerTorrent if $config.uploadRateLimitPerTorrent
  end

  # Returns true if the passed path is under the data dir path. That is, ensure that
  # the path is something we downloaded as a torrent. This is usually used for access control.
  def pathIsUnderDataDir(path)
    absDataDir = Pathname.new($config.dataDir).realpath.to_s
    absRequestedFile = Pathname.new(path).realpath.to_s
    absRequestedFile =~ /^#{absDataDir}/
  end

  def filesUnder(dir)
    Dir.new(dir).each{ |e|
      next if e[0,1] == '.'
      path = dir + "/" + e
      if File.directory?(path)
        filesUnder(path){ |f,d|
          yield f,d
        }
      else
        yield e, dir
      end
    }
  end
end
