require 'logger'
require 'syslog'

def makeFileLogger(filename, numFiles, fileSize)
  Logger.new(filename, numFiles, fileSize)
end

class SyslogWrapper
  FacilityHash = {
              "LOG_AUTH" => Syslog::LOG_AUTH,
              "LOG_AUTHPRIV" => Syslog::LOG_AUTHPRIV,
              "LOG_CRON" => Syslog::LOG_CRON,
              "LOG_DAEMON" => Syslog::LOG_DAEMON,
              "LOG_FTP" => Syslog::LOG_FTP,
              "LOG_KERN" => Syslog::LOG_KERN,
              "LOG_LOCAL0" => Syslog::LOG_LOCAL0,
              "LOG_LOCAL1" => Syslog::LOG_LOCAL1,
              "LOG_LOCAL2" => Syslog::LOG_LOCAL2,
              "LOG_LOCAL3" => Syslog::LOG_LOCAL3,
              "LOG_LOCAL4" => Syslog::LOG_LOCAL4,
              "LOG_LOCAL5" => Syslog::LOG_LOCAL5,
              "LOG_LOCAL6" => Syslog::LOG_LOCAL6,
              "LOG_LOCAL7 " => Syslog::LOG_LOCAL7,
              "LOG_LPR" => Syslog::LOG_LPR,
              "LOG_MAIL" => Syslog::LOG_MAIL,
              "LOG_NEWS" => Syslog::LOG_NEWS,
              "LOG_SYSLOG" => Syslog::LOG_SYSLOG,
              "LOG_USER" => Syslog::LOG_USER,
              "LOG_UUCP" => Syslog::LOG_UUCP
  }


  def initialize(ident, facility = nil)
    if facility
      @syslog = Syslog.open(ident, Syslog::LOG_PID, facility)
    else
      @syslog = Syslog.open(ident, Syslog::LOG_PID)
    end
  end

  def self.facilityNameToConst(name)
    FacilityHash[name]
  end

  def debug(msg)
    @syslog.debug escape(msg)
  end

  def info(msg)
    @syslog.info escape(msg)
  end

  def warn(msg)
    @syslog.warning escape(msg)
  end

  def error(msg)
    @syslog.err escape(msg)
  end

  def fatal(msg)
    @syslog.crit escape(msg)
  end

  private
  def escape(msg)
    # Convert single % to double. There is a bug in this syslog implementation where it seems like
    # the string is passed to the syslog(3) library function unchanged.
    pos = 0
    newmsg = ""
    while pos < msg.length
      b = msg[pos,1]
      newmsg << b
      if b == '%'
        newmsg << '%'
      end
      pos += 1
    end

    newmsg
  end
end

def makeSyslogLogger(ident, facility = nil)
  SyslogWrapper.new(ident, facility)
end

# Make a basic logger just in case.
$logger = Logger.new(STDERR)
