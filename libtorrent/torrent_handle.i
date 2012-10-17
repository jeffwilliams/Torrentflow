%{
// In the debian version of boost, asio is still a separate library.
#include "asio/ip/tcp.hpp"
#include "libtorrent/torrent_handle.hpp"
%}

namespace libtorrent {

  struct torrent_handle
  {
    torrent_handle();

    %exception {
      try {
        $action
      } catch (libtorrent::invalid_handle) {
        rb_raise(rb_eStandardError, "Invalid torrent handle");
      }
    }

    torrent_status status() const;
    //void get_download_queue(std::vector<partial_piece_info>& queue) const;
    void file_progress(std::vector<float>& progress);
    std::vector<announce_entry> const& trackers() const;
    void replace_trackers(std::vector<announce_entry> const&) const;
    void add_url_seed(std::string const& url);

    std::string name() const;

    bool has_metadata() const;

    %rename("valid?") is_valid() const;
    bool is_valid() const;

    %rename("seed?") is_seed() const;
    bool is_seed() const;

    %rename("paused?") is_paused() const;
    bool is_paused() const;

    void pause() const;
    void resume() const;

    void use_interface(const char* net_interface) const;
    entry write_resume_data() const;

    void force_reannounce() const;
    void force_reannounce(boost::posix_time::time_duration) const;

    %rename("upload_rate_limit=") set_upload_limit(int limit) const;
    void set_upload_limit(int limit) const;
    %rename("upload_rate_limit") upload_limit() const;
    int upload_limit() const;

    %rename("download_rate_limit=") set_download_limit(int limit) const;
    void set_download_limit(int limit) const;
    %rename("download_rate_limit") download_limit() const;
    int download_limit() const;

#if LIBTORRENT_VERSION_MINOR >= 14
    %rename("auto_managed=") auto_managed(bool m) const;
    void auto_managed(bool m) const;
#endif

#if LIBTORRENT_VERSION_MINOR == 13  
    void set_peer_upload_limit(asio::ip::tcp::endpoint ip, int limit) const;
    void set_peer_download_limit(asio::ip::tcp::endpoint ip, int limit) const;
#elif LIBTORRENT_VERSION_MINOR >= 14
    void set_peer_upload_limit(boost::asio::ip::tcp::endpoint ip, int limit) const;
    void set_peer_download_limit(boost::asio::ip::tcp::endpoint ip, int limit) const;
#endif

    %rename("ratio=") set_ratio(float up_down_ratio) const;
    void set_ratio(float up_down_ratio) const;

    %rename("max_uploads=") set_max_uploads(int max_uploads) const;
    void set_max_uploads(int max_uploads) const;

    %rename("max_connections=") set_max_connections(int max_connections) const;
    void set_max_connections(int max_connections) const;

    void set_tracker_login(std::string const& name , std::string const& password) const;

    boost::filesystem::path save_path() const;
#if LIBTORRENT_VERSION_MINOR <= 15
    void move_storage(boost::filesystem::path const& save_path) const;
#elif LIBTORRENT_VERSION_MINOR > 15
    void move_storage(std::string const& save_path) const;
#endif
    const sha1_hash& info_hash() const;

    %exception;

    %extend {
      libtorrent::torrent_info info() {
        try {
          return self->get_torrent_info();
        } catch (libtorrent::libtorrent_exception e) {
          rb_raise(rb_eStandardError, "info failed: %s", e.what());
        } catch (...) {
          rb_raise(rb_eStandardError, "info failed");
        }
      }


      VALUE peers() const {
        VALUE array = rb_ary_new();
        std::vector<libtorrent::peer_info> v;
        self->get_peer_info(v);
        for (std::vector<libtorrent::peer_info>::const_iterator i = v.begin();
             i != v.end(); ++i) {
          if (i->flags & libtorrent::peer_info::connecting ||
              i->flags & libtorrent::peer_info::handshake ||
              i->flags & libtorrent::peer_info::queued)
            continue;

          libtorrent::peer_info* p = new libtorrent::peer_info(*i);
          VALUE obj = SWIG_NewPointerObj(SWIG_as_voidptr(p), SWIGTYPE_p_libtorrent__peer_info, SWIG_POINTER_OWN);
          if (obj != Qnil) rb_ary_push(array, obj);
        }
        return array;
      }
    }
  };
}
