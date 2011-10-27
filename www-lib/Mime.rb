
# Singleton for handling extension to MIME type mapping

class Mime
  MimeTypesFile = "/etc/mime.types"
  @@instance = nil

  def self.instance
    if ! @@instance
      @@instance = Mime.new
    end
    @@instance
  end

  def initialize
    # Parse the mime types file
    parseMimeTypes
  end  
  
  def getMimeTypeOfFilename(file)
    ext = File.extname(file).downcase
    ext = ext[1,ext.length] if ext # Remove first .
    @mimeTypeHash[ext]
  end

  def dump(io)
    @mimeTypeHash.each{ |k,v|
      io.puts "#{k} ==> #{v}"
    }
  end

  private
  def parseMimeTypes
    @mimeTypeHash = {}
    File.open(MimeTypesFile,"r"){ |file|
      file.each_line{ |line|
        line.strip
        next if line.length == 0 || line[0,1] == '#'
        parts = line.split /\s+/
        if parts.size > 1
          mimeType = parts.shift
          parts.each{ |p|
            @mimeTypeHash[p] = mimeType
          }
        end
      } 
    }
  end
end

# Test
#inst = Mime.instance
#inst.dump($stdout)
#puts inst.getMimeTypeOfFilename("test.avi")
#puts inst.getMimeTypeOfFilename("test.rb")

