require 'yaml'

class Config
  TorrentConfigFilename = "torrentflowdaemon.conf"

  def initialize
    @listenPort = 3000
    @seedingTime = 3600
  end
  
  def load(filename)
    rc = true
    if File.exists?(filename)
      File.open(filename){ |fh|
        yaml = YAML::load(fh)
        return handleYaml(yaml)
      }
    else
      $syslog.info "Loading config file failed: file '#{filename}' doesn't exist."
    end
    rc
  end
  
  # This function searches the RUBY loadpath to try and find the standard config file.
  # If it's not found in the load path, the current directory and /etc/ are searched.
  # If found it returns the full path, if not it returns nil.
  def self.findConfigFile
    $:.reverse.each{ |e|
      path = "#{e}/#{TorrentConfigFilename}"
      return path if File.exists? path
    } 
  
    if File.exists?(TorrentConfigFilename)
      return TorrentConfigFilename
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

  private 
  def handleYaml(yaml)
    @listenPort = yaml['port'].to_i
    
    @torrentFileDir = yaml['torrent_file_dir']
    return false if ! validateDir(@torrentFileDir, 'torrent_file_dir')
    @dataDir = yaml['data_dir']
    return false if ! validateDir(@dataDir, 'data_dir')
    @passwordFile = yaml['password_file']
    if ! @passwordFile
      $syslog.info "Error: the configuration file had no 'password_file' setting."
      return false
    end

    @torrentPortLow = yaml['torrent_port_low'].to_i
    @torrentPortHigh = yaml['torrent_port_high'].to_i

    if ! @torrentPortLow || ! @torrentPortHigh
      $syslog.info "Error: the configuration file torrent_port_low and/or torrent_port_high settings are missing."
      return false
    end

    if @torrentPortLow > @torrentPortHigh
      $syslog.info "Error: the configuration file torrent_port_low is > torrent_port_high."
      return false
    end
    if @torrentPortLow == 0 || @torrentPortHigh == 0
      $syslog.info "Error: the configuration file torrent_port_low and/or torrent_port_high settings are invalid."
      return false
    end

    @outEncPolicy = yaml['out_enc_policy']
    @inEncPolicy = yaml['in_enc_policy']
    @allowedEncLevel = yaml['allowed_enc_level']

    @outEncPolicy = validateAndConvertEncPolicy(@outEncPolicy)
    if ! @outEncPolicy
      $syslog.info "Error: the configuration file out_enc_policy setting is invalid"
      return false
    end

    @inEncPolicy = validateAndConvertEncPolicy(@inEncPolicy)
    if ! @inEncPolicy
      $syslog.info "Error: the configuration file in_enc_policy setting is invalid"
      return false
    end

    @allowedEncLevel = validateAndConvertEncLevel(@allowedEncLevel)
    if ! @allowedEncLevel
      $syslog.info "Error: the configuration file allowed_enc_level setting is invalid"
      return false
    end

    @ratio = yaml['ratio']
    if @ratio
      f = @ratio.to_f
      if f != 0.0 && f < 1.0
        $syslog.info "Error: the configuration file ratio setting is invalid. Ratio must be 0, or a number >= 1.0"
        return false
      end
    else
      @ratio = 0
    end

    @seedingTime = yaml['seedingtime']
    if ! @seedingTime.is_a?(Integer)
      $syslog.info "Error: the configuration file seedingtime setting is invalid. It must be an integer"
      return false  
    end

    true
  end 
  
  def validateDir(dir, settingName)
    if ! dir
      $syslog.info "Error: the directory '#{dir}' specified by the #{settingName} configuration file setting is blank."
      return false;
    elsif ! File.exists?(dir)
      $syslog.info "Error: the directory '#{dir}' specified by the #{settingName} configuration file setting does not exist."
      return false;
    elsif ! File.directory?(dir)
      $syslog.info "Error: the directory '#{dir}' specified by the #{settingName} configuration file setting is not a directory."
      return false;
    elsif ! File.writable?(dir)
      $syslog.info "Error: the directory '#{dir}' specified by the #{settingName} configuration file setting is not writable by #{ENV['USER']}."
      return false;
    elsif ! File.readable?(dir)
      $syslog.info "Error: the directory '#{dir}' specified by the #{settingName} configuration file setting is not readable by #{ENV['USER']}."
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
end
