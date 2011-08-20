require 'socket'
include Socket::Constants

class GenericTcpClient
  F_GETFL = 3
  F_SETFL = 4
  O_NONBLOCK = 0x800

  def initialize(addr, port, doLog = true, logIo = $stdout)
    @addr = addr
    @port = port
    @logIo = $stdout
    @doLog = doLog
  end

  # Timeout in seconds (float)
  # Returns the connected socket on success
  def connect(timeout = nil)
    @logIo.puts "Client: Connecting to #{@addr}:#{@port}" if @doLog
  
    @socket = Socket.new(AF_INET, SOCK_STREAM, 0)
    addr = Socket.pack_sockaddr_in(@port, @addr)
    if timeout
      # Set nonblocking
      oldflags = @socket.fcntl(F_GETFL)
      begin
        @socket.connect_nonblock(addr)
      rescue Errno::EINPROGRESS
        rc = select(nil, [@socket], nil, timeout)
        if ! rc
          # Connect timed out
          raise "Connect timed out after #{timeout} seconds"
        elsif rc[2].size > 0
          raise "Connection error"
        end
      end
      @socket.fcntl(F_SETFL, oldflags)
    else
      @socket.connect(addr)
    end
    @socket
  end 
end
