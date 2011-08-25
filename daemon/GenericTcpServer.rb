require 'socket'
include Socket::Constants

class GenericTcpServer
  def initialize(port, addr="0.0.0.0", doLog = true, logIo = $stdout)
    @port = port
    @addr = addr
    @logIo = $stdout
    @doLog = doLog
  end

  # If a block is passed this method will call the block
  # when the server is up and running. The block should return quickly.
  def start(clientHandlerProc)
    @socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
    sockaddr = Socket.pack_sockaddr_in( @port, @addr )
    @socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
    @socket.bind( sockaddr )
    @socket.listen( 5 )

    yield if block_given?

    while true
      break if @exit

      sleep 0.1

      clientSock = nil
      begin
        clientSock, client_sockaddr = @socket.accept_nonblock
      rescue
        # Error, or nothing to accept.
        next
      end

      port, addr = Socket.unpack_sockaddr_in(client_sockaddr)
      if @doLog
        $syslog.info "Server: Got connection from #{addr}:#{port}" if @doLog
      end
      Thread.new(clientSock, addr, port){ |clientSock, addr, port|
        begin
          clientHandlerProc.call(clientSock, addr, port)
        rescue => e
          $syslog.info "Server: exception in client handler proc: #{$!}"
          $syslog.info e.backtrace.join("  ")
        end
      }
    end
    @socket.close
    $syslog.info "Server: exiting" if @doLog
  end

  def stop
    @exit = true
  end
end
