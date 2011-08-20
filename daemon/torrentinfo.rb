require "json" 

class TorrentInfo
  def initialize
    @values = {}
  end

  attr_accessor :values
  
  # The JSON encoded form is just the hash of key/values in the object
  def toJson
    JSON.generate(@values)
  end
end
