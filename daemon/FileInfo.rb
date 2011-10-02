class FileInfo
  def initialize
    @name = nil
    @type = nil
  end

  attr_accessor :name
  # Type is one of :file or :dir
  attr_accessor :type
  attr_accessor :size

  def self.createFrom(dir, file)
    path = "#{dir}/#{file}"
    return nil if ! File.exists?(path)
    
    rc = FileInfo.new
    if File.directory?(path)
      rc.type = :dir 
    else
      rc.type = :file 
    end

    rc.name = file
    rc.size = File.size path
    rc
  end
end

class DirContents
  def initialize(dir, files)
    @dir = dir
    @files = files
  end
  
  attr_accessor :dir
  attr_accessor :files
end
