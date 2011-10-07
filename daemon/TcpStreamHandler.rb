class TcpStreamHandler
  def initialize(socket)
    @socket = socket
  end

  # Send a stream of bytes of length 'length' read from io.
  def send(length, io)
    length = 0 if ! io
    # Send length as two 32 bit unsigned integers, high-order word first.
    length = length.abs
    packed = [length / 0x10000, length % 0x10000].pack("NN") # N == Long, network (big-endian) byte order
    @socket.print packed
    copyStream(io, @socket) if io
  end

  # Receive a stream of bytes and write it to the passed io
  # Returns the number of bytes written on success, or nil if there was a connection error
  def recv(io)
    binLen = nil
    begin
      binLen = @socket.read(8)
    rescue
    end
    return nil if ! binLen
    lengthArray = binLen.unpack("NN")
    length = lengthArray[0] * 0x10000 + lengthArray[1]

    begin
      copyStream(@socket,io,length)
      length   
    rescue
      nil
    end
  end

  private

  # This exists as copy_stream in Ruby 1.9 but not 1.8.
  def copyStream(src, dest, length = nil)
    bufferSize = 4096
    
    amtRead = 0
    while (!length) || (length && amtRead < length)
      toRead = bufferSize
      if length
        remaining = length-amtRead
        toRead = remaining if remaining < bufferSize
      end
      buf = src.read(toRead, buf)
      break if buf.nil? || buf.length == 0
      dest.print(buf)
      amtRead += buf.length
    end
  end
end

