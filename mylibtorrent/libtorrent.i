%module libtorrent

%include "std_string.i"
// This is to allow uint64_t to be treated as a number in ruby.
%include "stdint.i"

namespace libtorrent {
  typedef uint64_t size_type;
}

%include "fingerprint.i"
%include "bitfield.i"
%include "torrent_status.i"
%include "bencode.i"
%include "entry.i"
%include "peer_id.i"
%include "peer_request.i"
%include "torrent_info.i"
%include "peer_info.i"
%include "torrent_handle.i"
%include "storage.i"
%include "alert.i"
%include "session_settings.i"
%include "session.i"
%include "magnet_uri.i"
