%{
#include "libtorrent/peer_info.hpp"
// In the debian version of boost, asio is still a separate library.
#include "asio/ip/tcp.hpp"
%}

namespace libtorrent {
  struct peer_info
  {
    %rename("INTERESTING") interesting;
    %rename("CHOKED") choked;
    %rename("REMOTE_INTERESTED") remote_interested;
    %rename("REMOTE_CHOKED") remote_choked;
    %rename("SUPPORTS_EXTENSIONS") supports_extensions;
    %rename("LOCAL_CONNECTION") local_connection;
    %rename("HANDSHAKE") handshake;
    %rename("CONNECTING") connecting;
    %rename("QUEUED") queued;
    enum
    {
      interesting = 0x1,
      choked = 0x2,
      remote_interested = 0x4,
      remote_choked = 0x8,
      supports_extensions = 0x10,
      local_connection = 0x20,
      handshake = 0x40,
      connecting = 0x80,
      queued = 0x100
    };

    %rename("STANDARD_BITTORRENT") standard_bittorrent;
    %rename("WEB_SEED") web_seed;
    enum
    {
      standard_bittorrent = 0,
      web_seed = 1
    };

    %immutable;

    unsigned int flags;
#if LIBTORRENT_VERSION_MINOR == 13  
    boost::asio::ip::tcp::endpoint ip;
#elif LIBTORRENT_VERSION_MINOR == 14
    asio::ip::tcp::endpoint ip;
#endif
    float up_speed;
    float down_speed;
    float payload_up_speed;
    float payload_down_speed;
    size_type total_download;
    size_type total_upload;
    peer_id pid;
#if LIBTORRENT_VERSION_MINOR == 13  
    std::vector<bool> pieces;
#elif LIBTORRENT_VERSION_MINOR == 14
    libtorrent::bitfield pieces;
#endif
    bool seed;
    int upload_limit;
    int download_limit;

    size_type load_balancing;

    int download_queue_length;
    int upload_queue_length;
    int downloading_piece_index;
    int downloading_block_index;
    int downloading_progress;
    int downloading_total;

    std::string client;

    int connection_type;

    %mutable;
  };
}

