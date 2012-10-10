# This class represents a persistent error condition that exists in the daemon.
# An alarm can be 'raised' (in which case the condition is present) and 'lowered'
# in which case the condition is no longer present.
class Alarm
  def initialize(id, message)
    @id = id
    @message = message
  end

  attr_accessor :id
  attr_accessor :message

  def toHash
    {"id" => @id.to_s, "message" => @message}
  end
end
