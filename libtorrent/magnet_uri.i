%{
#include "libtorrent/session.hpp"
#include "libtorrent/magnet_uri.hpp"
%}

%{
  namespace libtorrent
  {
    torrent_handle add_magnet_uri(session& ses, std::string const& uri, std::string const& save_path, std::string name = NULL)
    {
      try {
        add_torrent_params params;
        params.save_path = save_path;
        params.name = strdup(name.c_str());
        return add_magnet_uri(ses, uri, params);
      } catch (libtorrent::libtorrent_exception e) {
        rb_raise(rb_eStandardError, "add_magnet_uri failed: %s", e.what());
      }
    }
  }
%}

#if LIBTORRENT_VERSION_MINOR < 16
namespace libtorrent
{
  torrent_handle add_magnet_uri(session& ses, std::string const& uri, std::string const& save_path, std::string name = NULL);
}
#endif
