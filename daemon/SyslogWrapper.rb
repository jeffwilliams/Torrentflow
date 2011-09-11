require 'syslog'

class SyslogWrapper
  @@syslog = nil
  
  def self.instance
    if ! @@syslog
      @@syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID)
    end
    @@syslog
  end
end
