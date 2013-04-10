class DataPoint
  def initialize(x,*values)
    @x = x
    @values = values
  end

  attr_accessor :x

  def value(i)
    @values[i]
  end
end


