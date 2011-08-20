
# This class can be used to hold a fixed number of samples at specific times.
# When the limit of samples is reached, then some samples are removed evenly over
# a time period (i.e. every second sample).
#
#
class TimeSampleHolder

  OldestGenerationCompactThreshold = 0.75

  # avgProc is a proc that given two samples returns a new sample which is the 
  # average of the two.
  def initialize(maxSamples, avgProc)
    @maxSamples = maxSamples
    @avgProc = avgProc
    @generations = []
    @totalSize = 0
  end

  def addSample(sample)
    gen = getGeneration(0)
    if @totalSize >= @maxSamples
#puts "Compacting on add. (#{sample})"
      compact
    end
     
    gen.push sample
    @totalSize += 1
  end

  def samples
    rc = []
    @generations.reverse_each{ |gen|
      gen.each{ |i|
        rc.push i
      }
    }
    rc
  end

  def to_s
    s = "Total size: #{@totalSize}\n"
    (@generations.size-1).downto(0){ |i|
      s << "Generation #{i} size: #{@generations[i].size}\n"
    }
    s
  end

  private
  def getGeneration(num)
    while (@generations.size-1) < num
      @generations.push []
    end
    @generations[num]
  end

  def compact
    
#puts @generations.size
    (@generations.size-1).times{ |i|
#puts "->Compact #{i}"
      compactGen(i)
    }

    # Only compact the last generation if it's grown too big
    if ( @maxSamples*OldestGenerationCompactThreshold < @generations.last.size )
      compactGen(@generations.size-1)
    end
  end
  
  # Compact a generation, moving it's samples from one generation to an older generation.
  def compactGen(fromGenNum)
    fromGen = getGeneration(fromGenNum)
    toGen = getGeneration(fromGenNum+1)
#puts "Compact gen #{fromGenNum} of size #{fromGen.size}"

    fromGen.size.times{ |i|
      # average this sample and the previous
      if (i % 2 == 1)
        val = @avgProc.call(fromGen[i], fromGen[i-1])
        toGen.push val
        @totalSize += 1
      end 
    }  
    @totalSize -= fromGen.size
    fromGen.clear
  end
end



# Testing

=begin

testAvg = Proc.new{ |a,b|
  a + b / 2
}

holder = TimeSampleHolder.new(100, testAvg)
puts
puts "Inserting 50 samples"
50.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 49 samples"
49.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 1 sample"
1.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 1 sample"
1.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 49 samples"
49.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 1 sample"
1.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 25 samples"
25.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 56 samples"
56.times{ |i|
  holder.addSample(i)
}
puts holder

puts
puts "Inserting 1 sample"
1.times{ |i|
  holder.addSample(i)
}
puts holder

=end
