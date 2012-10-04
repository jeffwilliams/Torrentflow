%{
#include <sstream>
#include "libtorrent/peer_id.hpp"
%}

namespace libtorrent {

  class big_number
  {
  public:

    %rename("SIZE") size;
    enum { size = number_size };

    big_number();

    void clear();

    %rename("zero?") is_all_zeros() const;
    bool is_all_zeros() const;

    bool operator==(big_number const& n) const;
    bool operator<(big_number const& n) const;
    big_number operator~();
    /*big_number& operator &= (big_number const& n);
    big_number& operator |= (big_number const& n);*/

    %extend {
      unsigned char const __getitem__(int i) const {
        return (*self)[i];
      }

      void __setitem__(int i, unsigned char c) {
        (*self)[i] = c;
      }

      VALUE __str__() const {
        std::ostringstream out;
        out << *self;
        return rb_str_new2(out.str().c_str());
      }

      bool __ne__(const big_number& n) const {
        return (*self != n);
      }
    }
  };

  typedef big_number peer_id;
  typedef big_number sha1_hash;

}

