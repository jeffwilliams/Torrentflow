# Download a file from a socket.
# This class can be used in two ways:
#
#   1. Create object and call recv. This will yield the length to the passed block (if specified) and then stream to file to the passed io.
#   2. Create object, call loadLength to get the length, then later call recv to stream the file.

class TcpStreamHandler
  def initialize(socket)
    @socket = socket
    @recvLength = nil
  end

  attr_reader :recvLength

  # Send a stream of bytes of length 'length' read from io.
  def send(length, io)
    length = 0 if ! io
    # Send length as two 32 bit unsigned integers, high-order word first.
    length = length.abs
    packed = [length / 0x10000, length % 0x10000].pack("NN") # N == Long, network (big-endian) byte order
    @socket.print packed
    copyStream(io, @socket) if io
  end

  def loadLength
    if @recvLength.nil?
      binLen = nil
      begin
        binLen = @socket.read(8)
      rescue
      end
      return nil if ! binLen
      lengthArray = binLen.unpack("NN")
      @recvLength = lengthArray[0] * 0x10000 + lengthArray[1]
    end
    @recvLength
  end

  # Receive a stream of bytes and write it to the passed io
  # Returns the number of bytes written on success, or nil if there was a connection error
  # If a block is passed, the expected size of the data to be read is passed to the block.
  def recv(io)
    loadLength
    
    if block_given?
      yield @recvLength
    end

    result = @recvLength
    begin
      copyStream(@socket,io,@recvLength)
    rescue
      result = nil
    end
    @recvLength = nil
    result
  end

  # Read the stream in chunks and pass each chunk to the block passed.
  def each
    loadLength

    readChunksFromStream(@socket, @recvLength) do |chunk|
      yield chunk
    end
  end

  private

  # This exists as copy_stream in Ruby 1.9 but not 1.8.
  def copyStream(src, dest, length = nil)
    readChunksFromStream(src, length) do |chunk|
      dest.print(chunk)
    end
  end

  def readChunksFromStream(src, length = nil)
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
      yield buf
      amtRead += buf.length
    end
  end
end

