%{
#include "libtorrent/peer_request.hpp"
%}

namespace libtorrent
{

  struct peer_request
  {
    int piece;
    int start;
    int length;

    bool operator==(peer_request const& r) const;
  };

}

