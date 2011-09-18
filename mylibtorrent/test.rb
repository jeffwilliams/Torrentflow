#!/usr/bin/ruby 
require "libtorrent.so"

def entryTypeToString(t)
  if t == Libtorrent::Entry::INTEGER
    "integer"
  elsif t == Libtorrent::Entry::STRING
    "string"
  elsif t == Libtorrent::Entry::LIST
    "list"
  elsif t == Libtorrent::Entry::DICTIONARY
    "dictionary"
  elsif t == Libtorrent::Entry::UNDEFINED
    "undefined"
  else
    "unknown"
  end
end

def termClearAndHome
  # Sent VT-100/ANSI sequence to clear screen
  print "\e[2J"
  # Sent VT-100/ANSI sequence to move cursor to "home"
  print "\e[H"
end

def stateToS(state)
  if state == Libtorrent::TorrentStatus::QUEUED_FOR_CHECKING
    "queued for checking"
  elsif state == Libtorrent::TorrentStatus::CHECKING_FILES ;
    "checking_files"
  elsif defined?(Libtorrent::TorrentStatus::CONNECTING_TO_TRACKER) && state == Libtorrent::TorrentStatus::CONNECTING_TO_TRACKER
    "connecting to tracker"
  elsif state == Libtorrent::TorrentStatus::DOWNLOADING_METADATA
    "downloading metadata"
  elsif state == Libtorrent::TorrentStatus::DOWNLOADING
    "downloading"
  elsif state == Libtorrent::TorrentStatus::FINISHED
    "finished"
  elsif state == Libtorrent::TorrentStatus::SEEDING
    "seeding"
  elsif state == Libtorrent::TorrentStatus::ALLOCATING
    "allocating"
  else
    "unknown"
  end
end

def printTorrentSummary(torrentHandle)
  print torrentHandle.info.name
  print " [paused]" if torrentHandle.status.paused?
  puts  

  print "  "
  print "state: " + stateToS(torrentHandle.status.state)
  print " progress: " + torrentHandle.status.progress.to_s
  print " peers: " + torrentHandle.status.num_peers.to_s
  print " downrate(B/s): " + torrentHandle.status.download_rate.to_s
  print " uprate(B/s): " + torrentHandle.status.upload_rate.to_s
  puts
end

session = Libtorrent::Session.new
session.alertMask = Libtorrent::Alert::STATUS_NOTIFICATION;

Torrent = "debian-6.0.2.1-i386-netinst.iso.torrent"
# Load the test torrent file
torrentInfo = Libtorrent::TorrentInfo::load(Torrent)
puts 
puts 
puts "Loaded torrent #{Torrent}."
puts "  Name: #{torrentInfo.name}"
puts "  Creator: #{torrentInfo.creator}"
puts "  Comment: #{torrentInfo.comment}"
puts "  Total size: #{torrentInfo.total_size}"
puts "  Piece size: #{torrentInfo.piece_length}"
puts "  Num files: #{torrentInfo.num_files}"
puts "  Valid: #{torrentInfo.valid?}"

# Add torrent
#session.add_torrent(
#  torrentInfo, "torrents", Libtorrent::Entry.new, Libtorrent::STORAGE_MODE_SPARSE, true)
session.add_torrent(
  torrentInfo, "torrents")

exitAt = nil
while true
  if exitAt && (Time.new > exitAt)
    break
  end
  
  torrentHandles = session.torrents
  #puts "get_torrents returned type #{torrents.class}"
  termClearAndHome
  torrentHandles.each{ |t|
    printTorrentSummary t
    # After we get to like 10% delete the torrent from the session, then exit after 5 s.
    if t.status.progress >= 0.25 && !exitAt
      puts "Deleting torrent from session"
      session.remove_torrent(t)
      exitAt = Time.new + 5
    end
  }

  alerts = session.alerts
  alerts.each{ |a|
    puts "Alert: #{a.message}"
  }
  
  sleep 2

end

