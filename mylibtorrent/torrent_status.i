%{
#include "libtorrent/torrent_handle.hpp"
#include "libtorrent/version.hpp"
%}

namespace libtorrent {

  struct torrent_status
  {
    torrent_status();

    %rename("QUEUED_FOR_CHECKING") queued_for_checking;
    %rename("CHECKING_FILES") checking_files;
#if LIBTORRENT_VERSION_MINOR == 13
    %rename("CONNECTING_TO_TRACKER") connecting_to_tracker;
#endif
    %rename("DOWNLOADING_METADATA") downloading_metadata;
    %rename("DOWNLOADING") downloading;
    %rename("FINISHED") finished;
    %rename("SEEDING") seeding;
    %rename("ALLOCATING") allocating;
#if LIBTORRENT_VERSION_MINOR == 14
    %rename("CHECKING_RESUME_DATA") checking_resume_data;
#endif
    enum state_t
    {
      queued_for_checking,
      checking_files,
#if LIBTORRENT_VERSION_MINOR == 13
      connecting_to_tracker,
#endif
      downloading_metadata,
      downloading,
      finished,
      seeding,
      allocating
#if LIBTORRENT_VERSION_MINOR == 14
      ,checking_resume_data
#endif
    };
 
    %immutable;

    state_t state;

    %rename("paused?") paused;
    bool paused;

    float progress;
    boost::posix_time::time_duration next_announce;
    boost::posix_time::time_duration announce_interval;

    std::string current_tracker;
    size_type total_download;
    size_type total_upload;
    size_type total_payload_download;
    size_type total_payload_upload;
    size_type total_failed_bytes;
    size_type total_redundant_bytes;
    float download_rate;
    float upload_rate;
    float download_payload_rate;
    float upload_payload_rate;
    int num_peers;
    int num_complete;
    int num_incomplete;

#if LIBTORRENT_VERSION_MINOR == 13  
    const std::vector<bool>* pieces;
#endif
#if LIBTORRENT_VERSION_MINOR == 14
    bitfield pieces;
#endif 

    int num_pieces;
    size_type total_done;
    size_type total_wanted_done;
    size_type total_wanted;
    int num_seeds;
    float distributed_copies;
    int block_size;

    %mutable;
  };

}
