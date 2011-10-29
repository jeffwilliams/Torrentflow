require 'mahoro'

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
    rc = @mimeTypeHash[ext]
    if ( ! rc )
      # File extension check failed. Use libmagic/file(1) through the mahoro lib
      begin
        mahMahoro = Mahoro.new(Mahoro::SYMLINK|Mahoro::MIME) # MAH MAHORO!
        rc = mahMahoro.file(file)
      rescue
        rc = nil
      end
    end
    rc
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
#puts inst.getMimeTypeOfFilename("../README")

