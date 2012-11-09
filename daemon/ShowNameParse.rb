#!/usr/bin/ruby
# This code is used to parse filenames that have "standard" TV show format, such as
#  Boardwalk.Empire.S02E01.720p.HDTV.x264-IMMERSE.mkv
# into seasons and episodes.

# Information that uniquely identifies an episode of a show.
class ShowEpisode
  def initialize
    @season = nil
    @episode = nil
  end
    
  attr_accessor :season
  attr_accessor :episode

  def to_s
    "S#{season}E#{episode}"
  end
end

# This class represents a contiguous range of episodes of a show in a single season. For example
# Season 1 Episodes 1-5, or Season 2 Episodes 7-9
class ShowEpisodeRange
  def initialize(season, startEpisode, endEpisode)
    @season = season
    @startEpisode = startEpisode
    @endEpisode = endEpisode
  end

  attr_accessor :startEpisode
  attr_accessor :endEpisode
  attr_accessor :season

  def size
    @endEpisode - @startEpisode + 1
  end

  # Given a list of ShowEpisode objects, return an array of ShowEpisodeRange objects
  # that represents the passed episodes.
  def self.createRanges(episodes)
    ranges = []
    sorted = episodes.sort{ |a,b|
      if a.season < b.season
        -1
      elsif a.season > b.season
        1
      else
        a.episode <=> b.episode
      end
    }

    firstInRange = nil
    lastProcessed = nil
    sorted.each{ |s|
      if ! firstInRange
        firstInRange = s
      else
        if s.season != lastProcessed.season || s.episode > lastProcessed.episode + 1
          # End of range!
          ranges.push ShowEpisodeRange.new(firstInRange.season, firstInRange.episode, lastProcessed.episode)
          firstInRange = s
        end 
      end  
      lastProcessed = s
    }
    if firstInRange
      ranges.push ShowEpisodeRange.new(firstInRange.season, firstInRange.episode, lastProcessed.episode)
    end 
    ranges
  end
 
end

# An object that stores a list of episode ranges for a single show.
class ShowEpisodes
  def initialize
    @showName = nil
    @episodes = []
  end
  
  attr_accessor :showName
  attr_accessor :episodes

  def episodeRanges
    ShowEpisodeRange.createRanges(@episodes)
  end
  
end

class ParsedShowName
  def initialize
  end
  
  attr_accessor :showName
  attr_accessor :season
  attr_accessor :episode

  def self.create(showName, season, episode)
    rc = ParsedShowName.new
    rc.showName = showName
    rc.season = season
    rc.episode = episode 
    rc
  end

  # Given a single episode raw string (as from a filename) in rawName, and given some metaInfo 
  # (such as the file's parent directory) returns an array of ParsedShowName objects  representing 
  # the episodes found in the string.
  #
  #   Format 1: Show.Name.S01E01.whatever.avi
  #   Format 2: Show.Name.S01E01E02.whatever.avi
  #   Format 3: Show Name season 3 episode 2 whatever.avi
  #   Format 4: Show.Name.1x2.whatever.avi
  def self.parse(rawName, metaInfo)
    rc = []


    if rawName =~ /^(.*)[sS](\d+)((?:[eE]\d+)+)/
      showName = self.fixShowName($1, metaInfo)
      season = $2.to_i
      # Parse the episode part; it might be more than one episode
      episodeStr = $3

      episodeStr.scan(/[eE](\d+)/){ |ep|
        episode = ep.first.to_i
        rc.push ParsedShowName.create(showName, season, episode)
      }
    # Format 3: "The Vampire Diaries Season 3 Episode 2",
    elsif rawName =~ /^(.*)season[^\d]+(\d+)[^\d]+episode[^\d]+(\d+)/i
      showName = self.fixShowName($1, metaInfo)
      season = $2.to_i
      # Parse the episode part; it might be more than one episode
      episode = $3.to_i
      rc.push ParsedShowName.create(showName, season, episode)
    # Format 4: 
    elsif rawName =~ /^(.*)(\d+)x(\d+)/
      showName = self.fixShowName($1, metaInfo)
      season = $2.to_i
      # Parse the episode part; it might be more than one episode
      episode = $3.to_i
      rc.push ParsedShowName.create(showName, season, episode)
    end
    rc
  end

  private
  def self.fixShowName(name, metaInfo)
    if name.length == 0 && metaInfo
      if metaInfo.parentDir
        name = File.basename(metaInfo.parentDir)
      end
    end

    name = name.tr('.',' ').strip
    # Strip off trailing and leading wierd characters.
    if name =~ /^[_\-]*([\sa-zA-Z0-9]+)[_\-]*$/
      name = $1
    end

    parts = name.strip.split(/\s+/)
    parts.collect!{ |e|
      e.capitalize
    }
    parts.join(' ')
  end
end

class FilenameMetaInfo
  def initialize
    @parentDir = nil
  end
  
  attr_reader :parentDir

  def setParentDir(p)
    @parentDir = p
    self
  end
end

# A class that can be used to parse a series of show names into an array of ShowEpisodes objects. 
class ShowNameInterpreter
  def initialize
    @names = []
    @metaInfo = []
  end

  def addName(name, metaInfo = nil)
    @names.push name
    @metaInfo.push metaInfo
  end
  
  # Process the episode names added with addName and return an array of ShowEpisodes objects.
  def processNames
    shows = {}
    i = 0
    @names.each{ |n|
      parsedArray = ParsedShowName.parse(n, @metaInfo[i])
      parsedArray.each{ |parsed|
        episodes = shows[parsed.showName]
        if ! episodes
          episodes = ShowEpisodes.new
          episodes.showName = parsed.showName
          shows[parsed.showName] = episodes
        end
        episode = ShowEpisode.new
        episode.season = parsed.season
        episode.episode = parsed.episode
        episodes.episodes.push episode
      }
      i += 1
    }
    shows
  end
end


#########
# Testing
#########


if $0 =~ /ShowNameParse.rb/

testdata = [
  "A-Ha - Take On Me.Mp3",
  "Boardwalk.Empire.S01E01.Boardwalk.Empire.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E02.The.Ivory.Tower.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E03.720p.HDTV.x264-CTU.mkv",
  "Boardwalk.Empire.S01E04.HDTV.XviD-2HD.avi",
  "Boardwalk.Empire.S01E05.Nights.in.Ballygran.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E06.Family.Limitation.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E07.Home.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E08.Hold.Me.in.Paradise.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E09.Belle.Femme.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E10.HDTV.XviD-FEVER.avi",
  "Boardwalk.Empire.S01E11.Paris.Green.HDTV.XviD-FQM.avi",
  "Boardwalk.Empire.S01E12.HDTV.XviD-FEVER.avi",
  "Boardwalk.Empire.S02E01.720p.HDTV.x264-IMMERSE.mkv",
  "Boardwalk.Empire.S02E02.HDTV.XviD-ASAP.avi",
  "Boardwalk.Empire.S02E03.720p.HDTV.x264-IMMERSE.mkv",
  "Boardwalk.Empire.S02E04.HDTV.XviD-ASAP.avi",
  "Boardwalk.Empire.S02E05.HDTV.XviD-LOL.avi",
  "DataRescue IDA Pro 5.1.0 Lin Advanced Edition - professional disassembler [h33t] [Original]",
  "DataRescue IDA Pro v5.2.0 Advanced Edition for WindowsLinuxMac professional disassembler, SDK and DataRescue Hex-Rays Decompiler v1.0 [h33t] [Original] [Must have]",
  "Dexter.S05E01.My.Bad.HDTV.XviD-FQM.avi",
  "Dexter.S06E01.HDTV.XviD-ASAP.avi",
  "Dexter.S06E02.Once.Upon.a.Time.HDTV.XviD-FQM.avi",
  "Dexter.S06E03.HDTV.XviD-ASAP.avi",
  "Dexter.S06E04.HDTV.XviD-LOL.avi",
  "Dexter.S06E06.HDTV.XviD-ASAP.avi",
  "download at superseeds.org True.Blood.S04E02.You.Smell.Like.Dinner.HDTV.XviD-XS.avi",
  "Family.Guy.S09E01.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E02.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E03.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E04.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E05.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E06.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E07E08.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E10.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E11.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E12.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E13.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E14.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E15.HDTV.XviD-LOL.avi",
  "Family.Guy.S09E18.HDTV.XviD-LOL.avi",
  "Farscape - Season 1-4+The.Peacekeeper.Wars.Part.1&2",
  "Firefly",
  "Frasier Season 9",
  "Futurama.S06E13.Holiday.Spectacular.HDTV.XviD-aAF.[VTV].avi",
  "Futurama.S06E14.Neutopia.HDTV.XviD-FQM.avi",
  "Futurama.S06E15.Benderama.HDTV.XviD-FQM.avi",
  "Futurama.S06E16.Ghost.in.the.Machines.HDTV.XviD-FQM.avi",
  "Futurama.S06E17.HDTV.XviD-ASAP.avi",
  "Futurama.S06E19.HDTV.XviD-ASAP.avi",
  "Futurama.S06E20.All.the.Presidents.Heads.HDTV.XviD-FQM.avi",
  "Futurama.S06E21.HDTV.XviD-ASAP.avi",
  "Futurama.S06E22.HDTV.XviD-ASAP.avi",
  "Futurama.S06E23.HDTV.XviD-ASAP.avi",
  "Futurama.S06E25.HDTV.XviD-ASAP.avi",
  "Futurama.S06E26.HDTV.XviD-ASAP.avi",
  "Game Of Thrones Season 1 - Complete",
  "Hanna [2011] BRRip XviD - CODY",
  "Homeland.S01E01.HDTV.XviD-ASAP.[VTV].avi",
  "Homeland.S01E02.Grace.HDTV.XviD-FQM.[VTV].avi",
  "Homeland.S01E03.HDTV.XviD-ASAP.[VTV].avi",
  "Homeland.S01E04.HDTV.XviD-ASAP.[VTV].avi",
  "House.S07E17.PROPER.HDTV.XviD-2HD.avi",
  "House.S07E18.HDTV.XviD-LOL.avi",
  "House.S07E19.HDTV.XviD-LOL.avi",
  "House.S07E20.HDTV.XviD-LOL.avi",
  "House.S07E21.HDTV.XviD-LOL.avi",
  "House.S07E22.HDTV.XviD-LOL.avi",
  "House.S07E23.Moving.On.HDTV.XviD-2HD.avi",
  "House.S08E01.HDTV.XviD-LOL.avi",
  "House.S08E02.HDTV.XviD-LOL.avi",
  "House.S08E03.HDTV.XviD-LOL.avi",
  "House.S08E04.HDTV.XviD-LOL.avi",
  "House.S08E05.HDTV.XviD-LOL.avi",
  "How.I.Met.Your.Mother.S05E11.Last.Cigarette.Ever.HDTV.XviD-FQM.[VTV].avi",
  "informants-1hr17min-md5-682bdf4a9c7e1918a286e00c0bc88c16.ogg",
  "KNOPPIX_V6.7.1CD-2011-09-14-EN",
  "Lord of Illusions",
  "Minority_Report.avi",
  "Necessary.Roughness.S01E09.HDTV.XviD-LOL.avi",
  "Nurse.Jackie.S03E06.When.The.Saints.Go.HDTV.XviD-FQM.avi",
  "Nurse.Jackie.S03E07.Orchids.and.Salami.PROPER.HDTV.XviD-FQM.avi",
  "Nurse.Jackie.S03E08.HDTV.XviD-ASAP.avi",
  "Nurse.Jackie.S03E09.HDTV.XviD-FEVER.avi",
  "Nurse.Jackie.S03E10.HDTV.XviD-LOL.avi",
  "Nurse.Jackie.S03E11.Batting.Practice.HDTV.XviD-FQM.avi",
  "Nurse.Jackie.S03E12.HDTV.XviD-ASAP.avi",
  "Rescue.Me.S07E07.Jeter.HDTV.XviD-FQM.avi",
  "Robot.Chicken.S05E01.HDTV.XviD-2HD.avi",
  "Robot.Chicken.S05E02.HDTV.XviD-2HD.avi",
  "Robot.Chicken.S05E03.HDTV.XviD-2HD.avi",
  "Robot.Chicken.S05E04.HDTV.XviD-2HD.avi",
  "Robot.Chicken.S05E05.HDTV.XviD-2HD.avi",
  "SlackerUprising_640x360.avi",
  "Terra.Nova.S01E01.Genesis.HDTV.XviD-FQM.avi",
  "Terra.Nova.S01E03.HDTV.XviD-LOL.avi",
  "Terra.Nova.S01E04.HDTV.XviD-LOL.avi",
  "Terra.Nova.S01E06.HDTV.XviD-LOL.avi",
  "The.Big.Bang.Theory.S04E19.PROPER.HDTV.XviD-FEVER.avi",
  "The.Big.Bang.Theory.S04E20.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S04E21.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S04E22.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S04E23.The.Engagement.Reaction.HDTV.XviD-FQM.avi",
  "The.Big.Bang.Theory.S04E24.The.Roomate.Transmogrification.HDTV.XviD-FQM.avi",
  "The.Big.Bang.Theory.S05E01.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S05E02.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S05E03.HDTV.XviD-ASAP.avi",
  "The Big Bang Theory S05E03 The Pulled Groin Extrapolation  HDTV Xvid DutchReleaseTeam (dutch subs nl)",
  "The.Big.Bang.Theory.S05E04.The.Wiggly.Finger.Catalyst.HDTV.XviD-FQM.avi",
  "The.Big.Bang.Theory.S05E05.The.Russian.Rocket.Reaction.HDTV.XviD-FQM.avi",
  "The.Big.Bang.Theory.S05E06.HDTV.XviD-ASAP.avi",
  "The.Big.Bang.Theory.S05E07.HDTV.XviD-2HD.avi",
  "The.Big.Bang.Theory.S05E08.HDTV.XviD-ASAP.avi",
  "The Big Bang Theory Season 5 Episode 6 - The Rhinitis Revelation",
  "The.Men.Who.Stares.At.Goats.2009.R5.Line.XviD-PrisM.avi",
  "The NeverEnding Story[1984]DvDrip[720x436]AC3[6ch][Eng]-RHooD",
  "The.Simpsons.S23E01.HDTV.XviD-LOL.avi",
  "The.Simpsons.S23E03.HDTV.XviD-LOL.avi",
  "The.Simpsons.S23E04.HDTV.XviD-LOL.avi",
  "The.Vampire.Diaries.S01E18.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S02E15.The.Dinner.Party.HDTV.XviD-FQM.avi",
  "The.Vampire.Diaries.S02E16.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S02E17.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S02E18.HDTV.XviD-2HD.jHONY.avi",
  "The.Vampire.Diaries.S02E19.PROPER.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S02E20.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S02E21.HDTV.XviD-ASAP.avi",
  "The.Vampire.Diaries.S02E22.As.I.Lay.Dying.HDTV.XviD-FQM.avi",
  "The.Vampire.Diaries.S03E01.HDTV.XviD-2HD",
  "the.vampire.diaries.s03e03.hdtv.xvid-2hd.avi",
  "The Vampire Diaries S03E04.avi",
  "The.Vampire.Diaries.S03E05.HDTV.XviD-P0W4.avi",
  "The.Vampire.Diaries.S03E06.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S03E07.HDTV.XviD-2HD.avi",
  "The.Vampire.Diaries.S03E08.REPACK.HDTV.XviD-2HD.avi",
  "The Vampire Diaries Season 3 Episode 2",
  "The.Walking.Dead.S01E01.Days.Gone.Bye.HDTV.XviD-FQM.[VTV].avi",
  "True.Blood.S04E01.HDTV.XviD-LOL.avi",
  "True.Blood.S04E02.You.Smell.Like.Dinner.PROPER.HDTV.XviD-FQM.avi",
  "True.Blood.S04E03.HDTV.XviD-LOL.avi",
  "True.Blood.S04E04.720p.HDTV.x264-IMMERSE.mkv",
  "True.Blood.S04E05.HDTV.XviD-ASAP.avi",
  "True.Blood.S04E06.HDTV.XviD-ASAP.avi",
  "True.Blood.S04E07.HDTV.XviD-ASAP.avi",
  "True.Blood.S04E08.HDTV.XviD-ASAP.avi",
  "True.Blood.S04E09.HDTV.XviD-LOL.avi",
  "True.Blood.S04E10.Burning.Down.the.House.PROPER.HDTV.XviD-FQM.avi",
  "True.Blood.S04E11.HDTV.XviD-LOL.avi",
  "True.Blood.S04E12.720p.HDTV.X264-DIMENSION.mkv",
  "Two.and.a.Half.Men.S09E01.HDTV.XviD-ASAP.avi",
  "Two.and.a.Half.Men.S09E02.HDTV.XviD-ASAP.avi",
  "Two.and.a.Half.Men.S09E03.HDTV.XviD-ASAP.avi",
  "Two.and.a.Half.Men.S09E04.HDTV.XviD-ASAP.avi",
  "Two.and.a.Half.Men.S09E05.A.Giant.Cat.Holding.a.Churro.HDTV.XviD-FQM.avi",
  "Two.and.a.Half.Men.S09E06.HDTV.XviD-ASAP.avi",
  "Two.and.a.Half.Men.S09E07.HDTV.XviD-ASAP.avi",
  "Wild.Boys.S01E01.WS.PDTV.XviD-BWB.avi",
  "YTMND - The Soundtrack (Remastered)"
]

if ARGV.size > 0
  directory = ARGV[0]
  if ! File.directory?(directory)
    puts "'#{dir}' is not a directory."
    exit 1
  end

  puts "Processing files under #{directory}"

  interp = ShowNameInterpreter.new

  def filesUnder(dir)
    Dir.new(dir).each{ |e|
      next if e[0,1] == '.'
      path = dir + "/" + e
      if File.directory?(path)
        filesUnder(path){ |f,d|
          yield f,d
        }
      else
        yield e, dir
      end
    }
  end

  filesUnder(directory){ |e, dir|
    if e[0,1] != '.'
      interp.addName(e, FilenameMetaInfo.new.setParentDir(dir))
    end
  }

  shows = interp.processNames
  shows.each{ |k,v|
    print k + ":"
    ranges = v.episodeRanges
    season = nil
    comma = true
    ranges.each{ |r|
      if ! season || season != r.season
        puts      
        print "  Season #{r.season}: "
        season = r.season
        comma = false
      end
      print "," if comma
      if r.size > 1
        print " #{r.startEpisode}-#{r.endEpisode}"
      else
        print " #{r.startEpisode}"
      end
      comma = true
    }
    puts
  }

  exit 0
end

class Test
  def initialize(caption)
    @caption = caption
  end

  def assert(bool, text = nil)
    if bool
      pass
    else
      fail(text)
    end
  end

  def equals(expected, actual)
    if expected == actual
      pass
    else
      fail("expected #{expected} but was #{actual}")
    end
  end

  def pass
    puts "[PASS] #{@caption}"
  end

  def fail(text = nil)
    rc = "[FAIL] #{@caption}"
    rc = rc << ": #{text}" if text
    puts rc
  end
end

def dotest(shows)
  # Check family guy
  episodes = shows["Family Guy"]
  t = Test.new("Family Guy was parsed")
  t.assert(episodes)
  if episodes
    t = Test.new("Family Guy ranges")
    ranges = episodes.episodeRanges
    t.equals(3,ranges.size) 
    if 3 == ranges.size
      t.equals(8,ranges[0].size)
      t.equals(6,ranges[1].size)
      t.equals(1,ranges[2].size)
      t.equals(1,ranges[0].startEpisode)
      t.equals(8,ranges[0].endEpisode)
      t.equals(10,ranges[1].startEpisode)
      t.equals(15,ranges[1].endEpisode)
      t.equals(18,ranges[2].startEpisode)
    end
  end

  # Check vampire diaries
  episodes = shows["The Vampire Diaries"]
  t = Test.new("Vampire Diaries was parsed")
  t.assert(episodes)
  if episodes
    t = Test.new("Vampire Diaries ranges")
    ranges = episodes.episodeRanges
    t.equals(3,ranges.size) 
    if 3 == ranges.size
      t.equals(1,ranges[0].size)
      t.equals(8,ranges[1].size)
      t.equals(8,ranges[2].size)
      t.equals(18,ranges[0].startEpisode)
      t.equals(18,ranges[0].endEpisode)
      t.equals(1,ranges[0].season)

      t.equals(15,ranges[1].startEpisode)
      t.equals(22,ranges[1].endEpisode)
      t.equals(2,ranges[1].season)

      t.equals(1,ranges[2].startEpisode)
      t.equals(8,ranges[2].endEpisode)
      t.equals(3,ranges[2].season)
    end
  end
end

dotest(shows)

end
