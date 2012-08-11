class Bucket
  def initialize(label = nil, criteriaData = nil, value = nil)
    @label = label
    @criteriaData = criteriaData
    @value = value
    @absoluteUsageAtStartOfBucket = nil
  end
  attr_accessor :label
  # Data used by BucketChangeCriteria to determine when we need a new bucket. 
  attr_accessor :criteriaData
  # At the time this bucket was created, the value of the absolute usage for all time
  attr_accessor :absoluteUsageAtStartOfBucket
  # The amount of usage for this bucket alone
  attr_accessor :value

  def clone
    Bucket.new(@label.clone, @criteriaData.clone, @value)
  end
end

class BucketChangeCriteria
  # Is it now time for a new bucket?
  def newBucket?(currentBucket)
    false
  end

  # Make a new bucket and return it.
  def newBucket
    innerNewBucket 
  end

  def innerNewBucket
    raise "Implement me!"
  end
end

class PeriodicBuckets
  def initialize(criteria, maxBuckets = nil)
    setBucketChangeCriteria(criteria)
    @buckets = []
    @maxBuckets = maxBuckets
    @maxBuckets = 1 if @maxBuckets && @maxBuckets < 1
  end

  # Set the criteria that determines when the current bucket is full
  # and we should make a new empty bucket the current bucket, and that is used
  # to set the label for the new bucket.
  def setBucketChangeCriteria(criteria)
    @bucketChangeCriteria = criteria
  end

  def update(absoluteUsage = nil)
    if @buckets.size == 0
      prev = nil
      @buckets.push @bucketChangeCriteria.newBucket
      setAbsoluteUsage(prev, @buckets.last, absoluteUsage) if absoluteUsage
    else
      prev = @buckets.last
      # Time for a new bucket?
      if @bucketChangeCriteria.newBucket?(@buckets.last)
        @buckets.push @bucketChangeCriteria.newBucket
        setAbsoluteUsage(prev, @buckets.last, absoluteUsage) if absoluteUsage
      end
      @buckets.shift if @maxBuckets && @buckets.size > @maxBuckets
    end

    setValue(@buckets.last, absoluteUsage) if absoluteUsage
  end

  def current(absoluteUsage = nil)
    @buckets.last
  end
  
  def all
    @buckets
  end

  private
  def setAbsoluteUsage(previousBucket, newBucket, absoluteUsage)
    if previousBucket
      newBucket.absoluteUsageAtStartOfBucket = previousBucket.absoluteUsageAtStartOfBucket + previousBucket.value
    else
      newBucket.absoluteUsageAtStartOfBucket = absoluteUsage
    end
  end
  def setValue(newBucket, absoluteUsage)
    newBucket.value = 
      absoluteUsage - 
      newBucket.absoluteUsageAtStartOfBucket
  end
end

class DailyBucketChangeCriteria < BucketChangeCriteria
  def newBucket?(currentBucket)
    now = Time.new
    currentBucket.criteriaData.day != now.day
  end

  def newBucket
    now = Time.new
    Bucket.new(now.strftime("%b %e"), now, 0)
  end
end

class MonthlyBucketChangeCriteria < BucketChangeCriteria
  def initialize(resetDay)
    @resetDay = resetDay
  end
  
  def newBucket?(currentBucket)
    Time.new > currentBucket.criteriaData
  end

  def newBucket
    now = Time.new
    # Set the bucket's criteriaData to the date after which we need a new bucket.
    nextMonth = now.mon % 12 + 1
    data = Time.local(now.year, nextMonth, @resetDay)
    Bucket.new(now.strftime("%b %Y"), data, 0)
  end
end


# For testing
class MinuteBucketChangeCriteria < BucketChangeCriteria
  def newBucket?(currentBucket)
    now = Time.new
    currentBucket.criteriaData.min != now.min
  end

  def newBucket
    now = Time.new
    Bucket.new(now.strftime("%H:%M"), now, 0)
  end
end

class UsageTracker
  def initialize(monthlyResetDay)
    @buckets = {}
    @buckets[:daily] = PeriodicBuckets.new(DailyBucketChangeCriteria.new,31)
    #@buckets[:minute] = PeriodicBuckets.new(MinuteBucketChangeCriteria.new,3)
    @buckets[:monthly] = PeriodicBuckets.new(MonthlyBucketChangeCriteria.new(monthlyResetDay),2)
  end

  def update(usageForAllTime)
    @buckets.each do |k,buckets|
      buckets.update usageForAllTime
    end
  end

  # Returns the usage as of the last time update() was called.
  # periodType should be :daily or :monthly
  def currentUsage(periodType)
    getBuckets(periodType).current
  end

  # Returns the usage as of the last time update() was called.
  def allUsage(periodType)
    getBuckets(periodType).all
  end

  private
  def getBuckets(type)
    buckets = @buckets[type]
    raise "Unsupported periodType #{periodType.to_s}" if ! buckets
    buckets
  end
end


if $0 =~ /UsageTracker.rb/
  # Testing
  tracker = UsageTracker.new
  
  abs = 200
  while true
    tracker.update(abs)
    
    puts
    puts "Usage for all time: #{abs}"
    puts "Buckets:"
    tracker.allUsage(:minute).each do |b|
      puts "  #{b.label}: #{b.value}"   
    end
    abs += 10
    sleep 10
  end  

end
