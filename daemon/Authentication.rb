require 'digest/md5'
require 'thread'

class Authentication
  class AccountInfo
    def initialize(login = nil, passwordhash = nil, salt = nil)
      @login = login
      @passwordhash = passwordhash
      @salt = salt
    end
    attr_accessor :login
    attr_accessor :passwordhash
    attr_accessor :salt
  end  

  class Session
    def initialize(sid = nil, login = nil)
      @sid = sid
      @login = login
      # Make a 1 hr session
      @expiry = Time.new + 60*60
    end
    attr_accessor :sid
    attr_accessor :login
    attr_accessor :expiry
  end

  def initialize
    @accounts = {}
    @sessions = {}
    @saltChars = %w{a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 1 2 3 4 5 6 7 8 9 0 _ % $ @ ! " ' . , < > }
    loadPasswordFile($config.passwordFile)
    @sessionMutex = Mutex.new

    # Start the audit thread
    Thread.new{ 
      sleep 10
      auditSessions
    }
  end

  # Returns true on success, false if the user cannot be authenticated
  def authorize(username, password)
    acct = @accounts[username]
    return false if ! acct
    hashed = hashPassword(password, acct.salt)
    hashed == acct.passwordhash
  end

  def addAccount(login, unhashedPassword)
    addAccountInternal($config.passwordFile, login, unhashedPassword)
  end
  
  # Start a new session for the specified user.
  # Returns the session id on success, nil on failure.
  def startSession(login)
    sid = nil
    while ! sid || @sessions.has_key?(sid)
      sid = makeRandomString(64)
    end
    @sessionMutex.synchronize{ 
      @sessions[sid] = Session.new(sid, login)
    }
    sid
  end

  def endSession(sid)
    @sessionMutex.synchronize{
      @sessions.delete sid
    }
  end
  
  def validSession?(sid)
    rc = false
    @sessionMutex.synchronize{
      rc = @sessions.has_key?(sid)
    }
    rc
  end

  private
  
  def loadPasswordFile(filename)
    if File.exists? filename
      File.open(filename, "r"){ |file|
        file.each_line{ |line|
          if line =~ /([^:]+):(.*):(.*)/
            @accounts[$1] = AccountInfo.new($1,$2,$3)
          end
        }
      }
    end
  end

  def addAccountInternal(filename, login, unhashedPassword)
    salt = makeRandomString(10)
    acct = AccountInfo.new(login, hashPassword(unhashedPassword, salt), salt)
    File.open(filename, "a"){ |file|
      file.puts "#{login}:#{acct.passwordhash}:#{salt}"
    }
    @accounts[login] = acct
  end

  def hashPassword(pass, salt)
    Digest::MD5.hexdigest(pass + salt)
  end

  def makeRandomString(len)
    rc = ""
    len.times{
      rc << @saltChars[rand(@saltChars.size)]
    }
    rc
  end

  def auditSessions
    # This should be implemented so that it only audits sessions for a certain 
    # amount of time to avoid blocking logins. It would only process a subset of 
    # logins each call.
    @sessionMutex.synchronize{
      @sessions.each{ |k,session|
        if session.expiry < Time.new
          @sessions.delete k
        end
      }
    }
  end 
end


