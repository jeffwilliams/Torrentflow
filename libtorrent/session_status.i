%{
#include "libtorrent/session.hpp"
%}

namespace libtorrent
{
  class session_status
  {
    public:
    bool has_incoming_connections;

    float upload_rate;
    float download_rate;

    float payload_upload_rate;
    float payload_download_rate;

    size_type total_download;
    size_type total_upload;

    size_type total_payload_download;
    size_type total_payload_upload;

    size_type total_redundant_bytes;
    size_type total_failed_bytes;

    int num_peers;
    int num_unchoked;
    int allowed_upload_slots;

    int up_bandwidth_queue;
    int down_bandwidth_queue;

  };
}


