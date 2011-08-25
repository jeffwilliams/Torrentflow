class GenericTcpMessageHandler
  F_GETFL = 3
  F_SETFL = 4

  def initialize(socket)
    @socket = socket
  end

  def send(object)
    data = Marshal.dump(object)
    binLen = [data.length].pack("N") # N == Long, network (big-endian) byte order
    @socket.print binLen
    @socket.print data
  end

  # Returns object
  def recv(timeout = nil)
    if timeout
      return readWithTimout(timeout)
    end

    binLen = @socket.read(4)
    return nil if ! binLen
    len = binLen.unpack("N")[0]
    msg = @socket.read(len)
    return nil if ! msg
    Marshal.load(msg)
  end

  private 
  def readWithTimout(timeout)
    rc = select([@socket], nil, nil, timeout)
    if ! rc
      # Read timed out
      raise "Read timed out after #{timeout} seconds"
    end
    binLen = @socket.read(4)
    return nil if ! binLen
    len = binLen.unpack("N")[0]
    rc = select([@socket], nil, nil, timeout)
    if ! rc
      # Read timed out
      raise "Read timed out after #{timeout} seconds"
    end
    msg = @socket.read(len)
    return nil if ! msg
    rc = Marshal.load(msg)
    rc
  end
end
