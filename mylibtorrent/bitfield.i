%{
#if LIBTORRENT_VERSION_MINOR == 14
#include "libtorrent/bitfield.hpp"
#endif
%}

namespace libtorrent {

#if LIBTORRENT_VERSION_MINOR == 14
  struct bitfield
  {
    bool get_bit(int index) const;
    void clear_bit(int index);
    void set_bit(int index);
    std::size_t size() const;
    bool empty() const;
    int count() const;
  };

#endif
}
