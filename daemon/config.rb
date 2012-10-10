require 'yaml'
require 'logging'

class TorrentflowConfig
  TorrentConfigFilename = "torrentflowdaemon.conf"

  def initialize
    @listenPort = 3000
    @seedingTime = 3600
  end
  
  # If dontValidateDirs is set, then the directories are not checked to 
  # see if they exist, etc. This should be set to true by non-daemon code that '
  # is reading the config file.
  def load(filename, dontValidateDirs = false)
    rc = true
    if File.exists?(filename)
      File.open(filename){ |fh|
        yaml = YAML::load(fh)
        return handleYaml(yaml, dontValidateDirs)
      }
    else
      $logger.info "Loading config file failed: file '#{filename}' doesn't exist."
    end
    rc
  end
  
  # This function searches the RUBY loadpath to try and find the standard config file.
  # If it's not found in the load path, the current directory, ../etc, etc/, and /etc/ are searched.
  # If found it returns the full path, if not it returns nil.
  def self.findConfigFile

    $:.reverse.each{ |e|
      path = "#{e}/#{TorrentConfigFilename}"
      return path if File.exists? path
    } 
  
    if File.exists?(TorrentConfigFilename)
      return TorrentConfigFilename
    elsif File.exists?("../etc/#{TorrentConfigFilename}")
      return Dir.pwd + "/../etc/#{TorrentConfigFilename}"
    elsif File.exists?("etc/#{TorrentConfigFilename}")
      return Dir.pwd + "/etc/#{TorrentConfigFilename}"
    elsif File.exists?("/etc/#{TorrentConfigFilename}")
      return "/etc/#{TorrentConfigFilename}"
    end
    nil
  end

  # Port to listen on
  attr_accessor :listenPort

  # Directory in which to store .torrent files
  attr_accessor :torrentFileDir
   
  # Directory in which to store torrent content
  attr_accessor :dataDir
  
  # Password file path
  attr_accessor :passwordFile
 
  # Port range to listen for torrent connections on
  attr_accessor :torrentPortLow
  attr_accessor :torrentPortHigh

  # Encryption settings
  attr_accessor :outEncPolicy
  attr_accessor :inEncPolicy
  attr_accessor :allowedEncLevel

  # Upload ratio
  attr_accessor :ratio
  attr_accessor :seedingTime

  attr_accessor :maxConnectionsPerTorrent
  attr_accessor :maxUploadsPerTorrent
  attr_accessor :downloadRateLimitPerTorrent
  attr_accessor :uploadRateLimitPerTorrent

  # Whether or not to enable the TV show summary in the UI
  attr_accessor :displayTvShowSummary

  # Usage tracking parameters
  attr_accessor :usageMonthlyResetDay
  attr_accessor :enableUsageTracking
  attr_accessor :dailyLimit
  attr_accessor :monthlyLimit

  # Mongo connection information
  attr_accessor :mongoDb
  attr_accessor :mongoUser
  attr_accessor :mongoPass
  attr_accessor :mongoHost
  attr_accessor :mongoPort

  # Logging
  attr_accessor :logType
  attr_accessor :logLevel
  attr_accessor :logFile
  attr_accessor :logLevel
  attr_accessor :logSize
  attr_accessor :logCount
  attr_accessor :logFacility

  private 
  def handleYaml(yaml, dontValidateDirs = false)
    @listenPort = yaml['port'].to_i
    
    @torrentFileDir = yaml['torrent_file_dir']
    return false if ! dontValidateDirs && ! validateDir(@torrentFileDir, 'torrent_file_dir')
    @dataDir = yaml['data_dir']
    return false if ! dontValidateDirs && ! validateDir(@dataDir, 'data_dir')
    @passwordFile = yaml['password_file']
    if ! @passwordFile
      $logger.error "The configuration file had no 'password_file' setting."
      return false
    end

    @torrentPortLow = yaml['torrent_port_low'].to_i
    @torrentPortHigh = yaml['torrent_port_high'].to_i

    if ! @torrentPortLow || ! @torrentPortHigh
      $logger.error "The configuration file torrent_port_low and/or torrent_port_high settings are missing."
      return false
    end

    if @torrentPortLow > @torrentPortHigh
      $logger.error "The configuration file torrent_port_low is > torrent_port_high."
      return false
    end
    if @torrentPortLow == 0 || @torrentPortHigh == 0
      $logger.error "The configuration file torrent_port_low and/or torrent_port_high settings are invalid."
      return false
    end

    @outEncPolicy = yaml['out_enc_policy']
    @inEncPolicy = yaml['in_enc_policy']
    @allowedEncLevel = yaml['allowed_enc_level']

    @outEncPolicy = validateAndConvertEncPolicy(@outEncPolicy)
    if ! @outEncPolicy
      $logger.error "The configuration file out_enc_policy setting is invalid"
      return false
    end

    @inEncPolicy = validateAndConvertEncPolicy(@inEncPolicy)
    if ! @inEncPolicy
      $logger.error "The configuration file in_enc_policy setting is invalid"
      return false
    end

    @allowedEncLevel = validateAndConvertEncLevel(@allowedEncLevel)
    if ! @allowedEncLevel
      $logger.error "The configuration file allowed_enc_level setting is invalid"
      return false
    end

    @ratio = yaml['ratio']
    if @ratio
      f = @ratio.to_f
      if f != 0.0 && f < 1.0
        $logger.error "The configuration file ratio setting is invalid. Ratio must be 0, or a number >= 1.0"
        return false
      end
    else
      @ratio = 0
    end

    @seedingTime = yaml['seedingtime']
    if ! @seedingTime.is_a?(Integer)
      $logger.error "The configuration file seedingtime setting is invalid. It must be an integer"
      return false  
    end

    @maxConnectionsPerTorrent = yaml['max_connections_per_torrent']
    if @maxConnectionsPerTorrent
      return false if ! validateInteger(@maxConnectionsPerTorrent, 'max_connections_per_torrent')
    end

    @maxUploadsPerTorrent = yaml['max_uploads_per_torrent']
    if @maxUploadsPerTorrent
      return false if ! validateInteger(@maxUploadsPerTorrent, 'max_uploads_per_torrent')
    end

    @downloadRateLimitPerTorrent = yaml['download_rate_limit_per_torrent']
    if @downloadRateLimitPerTorrent
      return false if ! validateInteger(@downloadRateLimitPerTorrent, 'download_rate_limit_per_torrent')
    end

    @uploadRateLimitPerTorrent = yaml['upload_rate_limit_per_torrent']
    if @uploadRateLimitPerTorrent
      return false if ! validateInteger(@uploadRateLimitPerTorrent, 'upload_rate_limit_per_torrent')
    end
  
    @displayTvShowSummary = yaml['display_tv_show_summary']
    if @displayTvShowSummary
      return false if ! validateBoolean(@displayTvShowSummary, 'display_tv_show_summary')
    end

    @enableUsageTracking = yaml['enable_usage_tracking']
    if @enableUsageTracking
      return false if ! validateBoolean(@enableUsageTracking, 'enable_usage_tracking')
    end

    @usageMonthlyResetDay = yaml['usage_monthly_reset_day']
    if @usageMonthlyResetDay
      return false if ! validateInteger(@usageMonthlyResetDay, 'usage_monthly_reset_day')
    end

    @dailyLimit = yaml['daily_limit']
    if @dailyLimit
      return false if ! validateInteger(@dailyLimit, 'daily_limit')
    end

    @monthlyLimit = yaml['monthly_limit']
    if @monthlyLimit
      return false if ! validateInteger(@monthlyLimit, 'monthly_limit')
    end

    @mongoDb = yaml['mongo_db']
    @mongoUser = yaml['mongo_user']
    @mongoPass = yaml['mongo_pass']
    @mongoHost = yaml['mongo_host']
    @mongoPort = yaml['mongo_port']
    if @mongoPort
      return false if ! validateInteger(@mongoPort, 'monthly_port')
    end

    @logType = validateAndConvertLogType(yaml['log_type'], 'log_type')
    return false if ! @logType

    if @logType == :file
      @logFile = yaml['log_file']
      if ! @logFile
        $logger.error "The configuration file log_file setting is missing"
        return false
      end
      @logLevel = validateAndConvertLogLevel(yaml['log_level'], 'log_level')
      return false if ! @logLevel
      @logSize = yaml['log_size']
      if @logSize
        return false if ! validateInteger(@logSize, 'log_size')
      else
        $logger.error "The configuration file log_size setting is missing"
        return false
      end

      @logCount = yaml['log_size']
      if @logCount
        return false if ! validateInteger(@logCount, 'log_size')
      else
        $logger.error "The configuration file log_size setting is missing"
        return false
      end
    elsif @logType == :syslog
      @logFacility = SyslogWrapper.facilityNameToConst(yaml['log_facility'])
      if ! @logFacility
        $logger.error "The configuration file log_facility setting is set to an invalid value: #{yaml['log_facility']} "
      end
    else
      $logger.error "Unknown log type #{yaml['log_type']}"
      return false
    end

    true
  end 
  
  def validateDir(dir, settingName)
    dir.untaint
    if ! dir
      $logger.error "The directory '#{dir}' specified by the #{settingName} configuration file setting is blank."
      return false;
    elsif ! File.exists?(dir)
      $logger.error "The directory '#{dir}' specified by the #{settingName} configuration file setting does not exist."
      return false;
    elsif ! File.directory?(dir)
      $logger.error "The directory '#{dir}' specified by the #{settingName} configuration file setting is not a directory."
      return false;
    elsif ! File.writable?(dir)
      $logger.error "The directory '#{dir}' specified by the #{settingName} configuration file setting is not writable by #{ENV['USER']}."
      return false;
    elsif ! File.readable?(dir)
      $logger.error "The directory '#{dir}' specified by the #{settingName} configuration file setting is not readable by #{ENV['USER']}."
      return false;
    end
  
    true    
  end

  def validateAndConvertEncPolicy(policy)
    if policy == 'forced'
      return :forced
    elsif policy == 'enabled'
      return :enabled
    elsif policy == 'disabled'
      return :disabled
    else
      return nil
    end
  end

  def validateAndConvertEncLevel(level)
    if level == 'plaintext'
      return :plaintext
    elsif level == 'rc4'
      return :rc4
    elsif level == 'both'
      return :both
    else
      return nil
    end
  end

  def validateInteger(s, settingName)
    if s.is_a?(Integer)
      true
    else
      $logger.error "#{settingName} must be an integer but is '#{s}'"
      false
    end
  end

  def validateBoolean(s, settingName)
    if s.is_a?(TrueClass) || s.is_a?(FalseClass)
      true
    else
      $logger.error "#{settingName} must be a boolean value (true/false) but is '#{s}'"
      false
    end
  end

  def validateAndConvertLogType(type, settingName)
    if type == 'file'
      return :file
    elsif type == 'syslog'
      return :syslog
    else
      $logger.error "#{settingName} must be 'file' or 'syslog'"
      return nil
    end
  end

  def validateAndConvertLogLevel(level, settingName)
    if level == "debug"
      Logger::DEBUG
    elsif level == "info"
      Logger::INFO
    elsif level == "warn"
      Logger::WARN
    elsif level == "error"
      Logger::ERROR
    elsif level == "fatal"
      Logger::FATAL
    else
      $logger.error "#{settingName} must be debug, info, warn, error, or fatal"
      nil
    end
  end
end
