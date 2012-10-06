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

  def toHash
    {"label" => @label, "absoluteUsageAtStartOfBucket" => @absoluteUsageAtStartOfBucket, "criteriaData" => @criteriaData, "value" => @value}
  end
  def fromHash(hash)
    @label = hash["label"]
    @absoluteUsageAtStartOfBucket = hash["absoluteUsageAtStartOfBucket"]
    @criteriaData = hash["criteriaData"]
    @value = hash["value"]
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

  def toHash
    array = []
    @buckets.each do |b|
      array.push b.toHash 
    end
    { "buckets" => array }
  end

  def fromHash(hash)
    @buckets = []
    hash["buckets"].each do |b|
      bucket = Bucket.new(nil, nil, nil)
      bucket.fromHash b
      @buckets.push bucket
      #bucket.criteriaData = @bucketChangeCriteria.criteriaData
    end
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

  def criteriaData
    now = Time.new
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
    data = criteriaData
    Bucket.new(now.strftime("%b %Y"), data, 0)
  end

  def criteriaData
    now = Time.new
    nextMonth = now.mon % 12 + 1
    Time.local(now.year, nextMonth, @resetDay)
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
  def initialize(monthlyResetDay, mongoDb = nil)
    @buckets = {}
    @buckets[:daily] = PeriodicBuckets.new(DailyBucketChangeCriteria.new,31)
    #@buckets[:minute] = PeriodicBuckets.new(MinuteBucketChangeCriteria.new,3)
    @buckets[:monthly] = PeriodicBuckets.new(MonthlyBucketChangeCriteria.new(monthlyResetDay),2)
    @mongoDb = mongoDb
    @usageForAllTimeAdjustment = 0
    loadBucketsFromMongo
  end

  attr_accessor :mongoDb

  # Update the UsageTracker with more usage. The value passed
  # should be the usage since the torrentflow session was created.
  # If Mongo is not used, then this means stopping and starting the session
  # will cause UsageTracking to only track usage for the session. However
  # if Mongo is used then the usage can be saved and persisted between sessions
  # and internally the value passed here is added to the value loaded from Mongo.
  def update(usageForAllTime)
    usageForAllTime += @usageForAllTimeAdjustment
    @buckets.each do |k,buckets|
      buckets.update usageForAllTime
    end
    saveBucketsToMongo
  end

  # This method returns the usage in the current bucket for the specified
  # period type (:daily or :monthly). The usage is accurate as of the last 
  # time update() was called.
  # The returned value is a single Bucket object.
  def currentUsage(periodType)
    getBuckets(periodType).current
  end

  # Returns the usage as of the last time update() was called.
  # This method returns all the tracked usage for the specified
  # period type (:daily or :monthly). The usage is accurate as of the last 
  # time update() was called.
  # The returned value is an array of Bucket objects.
  def allUsage(periodType)
    getBuckets(periodType).all
  end

  private
  def getBuckets(type)
    buckets = @buckets[type]
    raise "Unsupported periodType #{periodType.to_s}" if ! buckets
    buckets
  end

  def saveBucketsToMongo
    if @mongoDb
      dailyCollection = @mongoDb.collection("daily_usage")
      monthlyCollection = @mongoDb.collection("monthly_usage")
      # Remove all previous documents
      dailyCollection.remove
      monthlyCollection.remove

      dailyCollection.insert @buckets[:daily].toHash
      monthlyCollection.insert @buckets[:monthly].toHash
    end
  end

  def loadBucketsFromMongo
    if @mongoDb
      dailyCollection = @mongoDb.collection("daily_usage")
      monthlyCollection = @mongoDb.collection("monthly_usage")

      arr = dailyCollection.find_one
      @buckets[:daily].fromHash arr if arr
      arr = monthlyCollection.find_one
      @buckets[:monthly].fromHash arr if arr

      # If we are loading from Mongo it means that the absolute usage returned from the torrentflow session will not
      # contain the usage that we previously tracked, so we must add the old tracked value to what the torrentflow
      # session reports.
      @usageForAllTimeAdjustment = @buckets[:daily].current.absoluteUsageAtStartOfBucket + @buckets[:daily].current.value
      SyslogWrapper.info "Loading usage from Mongo."
      SyslogWrapper.info "Absolute usage at start of current daily bucket: " + @buckets[:daily].current.absoluteUsageAtStartOfBucket.to_s
      SyslogWrapper.info "Usage in current daily bucket: " + @buckets[:daily].current.value.to_s
      SyslogWrapper.info "Usage for all time adjustment: " + @usageForAllTimeAdjustment.to_s
    else
      SyslogWrapper.info "Not loading usage from Mongo."
    end
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
