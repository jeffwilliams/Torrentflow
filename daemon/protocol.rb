
class DaemonRequest
end

class DaemonResponse
  def initialize
    @successful = true
    @errorMsg = ""
  end
  
  attr_accessor :successful
  attr_accessor :errorMsg
end

####### REQUESTS ########
class DaemonListTorrentsRequest < DaemonRequest
  # dataToGet is an array of symbols representing the data fields expected on return for
  # each torrent object.
  def initialize(dataToGet = [], torrentId = nil)
    @dataToGet = dataToGet
    @torrentId = torrentId
    raise "initialize method takes an array" if ! dataToGet.is_a?(Array)
  end
  
  attr_reader :dataToGet
  attr_reader :torrentId
end

class DaemonAddTorrentRequest < DaemonRequest
  def initialize(filepath = nil)
    @filepath = filepath
  end

  attr_accessor :filepath
end

class DaemonDelTorrentRequest < DaemonRequest
  def initialize(torrentName = nil, deleteFiles = false)
    @torrentName = torrentName
    @deleteFiles = deleteFiles
  end

  attr_accessor :torrentName
  attr_accessor :deleteFiles
end

# Get a torrent from disk or from a URL, and store it in 
# the .torrent file storage directory. The response contains
# the path to the file.
class DaemonGetTorrentRequest < DaemonRequest
  # sourcePath should be set to a file path on the harddrive, or 
  # a URL for a torrent file. filetype should be set to :disk or 
  # :url for the different cases.
  def initialize(sourcePath, filetype, finalFilename = nil)
    @sourcePath = sourcePath
    @filetype = filetype
    @finalFilename = finalFilename
    raise "Invalid filetype '#{filetype.to_s}'" if filetype != :url && filetype != :disk
  end

  attr_accessor :sourcePath 
  attr_accessor :filetype
  attr_accessor :finalFilename
  
end

class DaemonGetMagnetRequest < DaemonRequest
  def initialize(sourcePath)
    @sourcePath = sourcePath
  end

  attr_accessor :sourcePath 
end

class DaemonTerminateRequest < DaemonRequest
end

class DaemonLoginRequest < DaemonRequest
  def initialize(login, password)
    @login = login
    @password = password
  end
  attr_accessor :login
  attr_accessor :password
end

class DaemonAuthSessionRequest < DaemonRequest
  def initialize(sid)
    @sid = sid
  end
  attr_accessor :sid
end

class DaemonLogoutRequest < DaemonRequest
  def initialize(sid)
    @sid = sid
  end
  attr_accessor :sid
end

class DaemonPauseTorrentRequest < DaemonRequest
  def initialize(torrentName = nil)
    @torrentName = torrentName
  end
  attr_accessor :torrentName
end

class DaemonGetAlertsRequest < DaemonRequest
  def initialize(torrentName = nil)
    @torrentName = torrentName
  end
  attr_accessor :torrentName
end


class DaemonFsInfoRequest < DaemonRequest
end

class DaemonGraphInfoRequest < DaemonRequest
  def initialize(torrentId = nil)
    @torrentId = torrentId
  end
  
  attr_reader :torrentId
end

class DaemonListFilesRequest < DaemonRequest
  def initialize(dir = nil)
    @dir = dir
  end

  attr_reader :dir
end

# The response to this request is not a DaemonResponse, but
# instead a length and a stream of bytes, that can be handled
# using TcpStreamHandler
class DaemonDownloadFileRequest < DaemonRequest
  def initialize(path)
    @path = path
  end

  attr_reader :path
end

# This is a request to delete a file that was downloaded 
# as part of a torrent.
class DaemonDelFileRequest < DaemonRequest
  def initialize(path)
    @path = path
  end

  attr_reader :path
end

# Get a list of shows by parsing the filenames in 
# the datadir
class DaemonGetTvShowSummaryRequest < DaemonRequest
end

# Get the usage (volume of bytes) that have been uploaded and downloaded for different periods (today, this month, etc)
class DaemonGetUsageRequest < DaemonRequest
  def initialize(type, qty)
    @type = type
    @qty = qty
  end

  attr_accessor :type
  attr_accessor :qty
end

####### RESPONSES ########
class DaemonListTorrentsResponse < DaemonResponse
  def initialize
    super
    @torrents = []
  end

  # torrents is an array of TorrentInfo objects.
  attr_accessor :torrents
end

class DaemonAddTorrentResponse < DaemonResponse
end

class DaemonDelTorrentResponse < DaemonResponse
end

class DaemonGetTorrentResponse < DaemonResponse
  def initialize
    super
    @path = path
  end
  
  attr_accessor :path
end

class DaemonGetMagnetResponse < DaemonResponse
  def initialize
    super
  end
end

class DaemonTerminateResponse < DaemonResponse
end

class DaemonLoginResponse < DaemonResponse
  def initialize(sid = nil)
    @sid = sid
    super()
  end

  attr_accessor :sid
end

class DaemonAuthSessionResponse < DaemonResponse
  def initialize
    super
  end
end

class DaemonLogoutResponse < DaemonResponse
  def initialize
    super
  end
end

class DaemonPauseTorrentResponse < DaemonResponse
  def initialize
    super
  end
end

class DaemonGetAlertsResponse < DaemonResponse  
  def initialize(alerts = [])
    @alerts = alerts
    super()
  end

  attr_accessor :alerts
end

class DaemonFsInfoResponse < DaemonResponse
  def initialize
    super
    @freeSpace = 0
    @usedSpace = 0
    @totalSpace = 0
    @usePercent = 0
  end

  attr_accessor :freeSpace
  attr_accessor :usedSpace
  attr_accessor :totalSpace
  attr_accessor :usePercent
end

class DaemonGraphInfoResponse < DaemonResponse
  def initialize
    super
    @dataPoints = nil
  end
  attr_accessor :dataPoints
end

class DaemonListFilesResponse < DaemonResponse
  def initialize
    super
    @files = []
    @dir = nil
  end

  attr_accessor :files
  # The directory containing the files
  attr_accessor :dir
end

class DaemonDelFileResponse < DaemonResponse
  def initialize
    super
  end
end

# Get a list of shows by parsing the filenames in 
# the datadir.
# The showRanges attribute is a hashtable; the key is the 
# showname, and the value is a list of ShowEpisodeRange objects 
# (having startEpisode, endEpisode, and season properties)

class DaemonGetTvShowSummaryResponse < DaemonResponse
  def initialize()
    @showRanges = {}
  end
  
  attr_accessor :showRanges
end

# Get the usage (volume of bytes) that have been uploaded and downloaded for different periods (today, this month, etc)
class DaemonGetUsageResponse < DaemonResponse
  
  def initialize(buckets = nil)
    @buckets = buckets
  end

  attr_accessor :buckets
end
