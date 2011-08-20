class TestingTorrentList
  def initialize
    @torrents = [] 
    @words = ["desk","computer","debian","redhat","suse","dasani","book","hand","potato","phone","burning", "wheel","sassy","pants","red"]
  end

  attr_accessor :torrents

  def updateTorrents
=begin
      rand(2).times{ 
        delTorrent
      }
=end
    (rand(3)+1).times{
      addTorrent
    }
  end
  def delTorrent
    r = rand(@torrents.size)
    if @torrents[r]
      @words.push(@torrents[r][:name])
      @torrents[r] = nil
    end
    @torrents.compact!
  end
  def addTorrent(name = nil)
    return if @torrents.size >= 14
    if ! name
      name = @words.shift
    end
    return if ! name
    @torrents.each{ |t|
      return if t[:name] == name
    }

    r = rand(8);
    state = nil
    if r == 0
      state = :checking_files
    elsif r == 1
      state = :connecting_to_tracker
    elsif r == 2
      state = :downloading_metadata
    elsif r == 3
      state = :downloading
    elsif r == 4
      state = :finished
    elsif r == 5
      state = :seeding
    elsif r == 6
      state = :queued_for_checking
    elsif r == 7
      state = :allocating
    end

    hash = { 
      :name => name,
      :creator => @words[rand(@words.size)],
      :total_size => 10000,
      :piece_size => 512,
      :num_files => 1,
      :valid => true,
      :state => state,
      :progress => 0.34,
      :num_peers => 34,
      :download_rate => 14.0,
      :upload_rate => 26.0
    }
    @torrents.push hash
  end
end

$testingTorrentList = TestingTorrentList.new

