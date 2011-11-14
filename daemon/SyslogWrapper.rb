require 'syslog'

class SyslogWrapper
  @@syslog = nil
  
  def self.instance
    if ! @@syslog
      @@syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID)
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
end

# test
#SyslogWrapper.info "My percent: %5D"

