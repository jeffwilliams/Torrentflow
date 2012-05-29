require 'syslog'

class SyslogWrapper
  @@syslog = nil
  @@facility = nil
  
  def self.instance
    if ! @@syslog
      if @@facility
        @@syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID, @@facility)
      else
        @@syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID)
      end
    end
    @@syslog
  end

  def self.info(msg)
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

    self.instance.info newmsg
  end

  def self.setFacility(str)
    hash = {
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
              "LOG_LOCAL7 " => Syslog::LOG_LOCAL7 ,
              "LOG_LPR" => Syslog::LOG_LPR,
              "LOG_MAIL" => Syslog::LOG_MAIL,
              "LOG_NEWS" => Syslog::LOG_NEWS,
              "LOG_SYSLOG" => Syslog::LOG_SYSLOG,
              "LOG_USER" => Syslog::LOG_USER,
              "LOG_UUCP" => Syslog::LOG_UUCP
    }
  
    @@facility = hash[str.upcase]
    if @@facility && @@syslog
      # Re-open syslog with the new facility
      @@syslog.close
      @@syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID, @@facility)
    elsif ! @@facility
      $stdout.puts "Unknown syslog facility '#{str}'"
    end
  end
end

# test
#SyslogWrapper.info "My percent: %5D"

