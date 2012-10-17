%{
#include "libtorrent/session.hpp"
#include "boost/filesystem/path.hpp"
%}

namespace libtorrent
{
  class session
  {
    public:
    session(fingerprint const& print = fingerprint("LT", 
      LIBTORRENT_VERSION_MAJOR, LIBTORRENT_VERSION_MINOR, 0, 0));

    session(
      fingerprint const& print,
      std::pair<int, int> listen_port_range,
      char const* listen_interface = "0.0.0.0");
  
    ~session();

    %rename("NONE") none;
    %rename("DELETE_FILES") delete_files;
    enum options_t
    {
      none = 0,
      delete_files = 1
    };

#if LIBTORRENT_VERSION_MINOR >= 14
    %rename("alertMask=") set_alert_mask(int m);
    void set_alert_mask(int m);
#endif

    libtorrent::session_status status() const;

    void remove_torrent(const torrent_handle& h, int options = none);
    torrent_handle find_torrent(sha1_hash const& info_hash) const;

    unsigned short listen_port() const;
    %rename("listening?") is_listening() const;
    bool is_listening() const;

    void set_pe_settings(pe_settings const& settings);
    pe_settings const& get_pe_settings() const;

    %extend {
      torrent_handle add_torrent(
        torrent_info& ti,
        const char* save_path
      )
      {
        libtorrent::add_torrent_params params;
        params.ti = boost::intrusive_ptr<libtorrent::torrent_info>(new libtorrent::torrent_info(ti));
        params.save_path = save_path;
        try {
          return self->add_torrent( params );
        } catch (libtorrent::libtorrent_exception e) {
          rb_raise(rb_eStandardError, "add_torrent failed: %s", e.what());
        }
      }

      
#if LIBTORRENT_VERSION_MINOR >= 16
      /* For downloading magnet links */
      torrent_handle add_torrent_url(
        const char* url,
        const char* save_path
      )
      {
        libtorrent::add_torrent_params params;
        params.url = url;
        params.save_path = save_path;
        try {
          return self->add_torrent( params );
        } catch (libtorrent::libtorrent_exception e) {
          rb_raise(rb_eStandardError, "add_torrent failed: %s", e.what());
        }
      }
#endif

      VALUE torrents() {
        VALUE array = rb_ary_new();
        std::vector<libtorrent::torrent_handle> tv = self->get_torrents();
        for (std::vector<libtorrent::torrent_handle>::const_iterator i = tv.begin();
             i != tv.end(); ++i) {
          libtorrent::torrent_handle*p = new libtorrent::torrent_handle(*i);
          VALUE obj = SWIG_NewPointerObj(SWIG_as_voidptr(p), SWIGTYPE_p_libtorrent__torrent_handle, SWIG_POINTER_OWN);
          if (obj != Qnil) rb_ary_push(array, obj);
        }
        return array;
      }

      bool listen_on(int port) {
        return self->listen_on(std::make_pair(port, port));
      }

      bool listen_on(int low_port, int high_port) {
        return self->listen_on(std::make_pair(low_port, high_port));
      }

      VALUE alerts() {
        VALUE array = rb_ary_new();
        libtorrent::alert* ptr; 

        while ((ptr = self->pop_alert().release())) {
          swig_type_info* swig_type = NULL;

          if (dynamic_cast<libtorrent::fastresume_rejected_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__fastresume_rejected_alert;
          } else if (dynamic_cast<libtorrent::file_error_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__file_error_alert;
          } else if (dynamic_cast<libtorrent::hash_failed_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__hash_failed_alert;
          } else if (dynamic_cast<libtorrent::invalid_request_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__invalid_request_alert;
          } else if (dynamic_cast<libtorrent::listen_failed_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__listen_failed_alert;
          } else if (dynamic_cast<libtorrent::metadata_failed_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__metadata_failed_alert;
          } else if (dynamic_cast<libtorrent::metadata_received_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__metadata_received_alert;
          } else if (dynamic_cast<libtorrent::peer_ban_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__peer_ban_alert;
          } else if (dynamic_cast<libtorrent::peer_error_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__peer_error_alert;
          } else if (dynamic_cast<libtorrent::torrent_finished_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__torrent_finished_alert;
          } else if (dynamic_cast<libtorrent::tracker_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__tracker_alert;
          } else if (dynamic_cast<libtorrent::tracker_announce_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__tracker_announce_alert;
          } else if (dynamic_cast<libtorrent::tracker_reply_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__tracker_reply_alert;
          } else if (dynamic_cast<libtorrent::tracker_warning_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__tracker_warning_alert;
          } else if (dynamic_cast<libtorrent::url_seed_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__url_seed_alert;
          } else if (dynamic_cast<libtorrent::block_downloading_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__block_downloading_alert;
          } else if (dynamic_cast<libtorrent::block_finished_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__block_finished_alert;
          } else if (dynamic_cast<libtorrent::listen_succeeded_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__listen_succeeded_alert;
          } else if (dynamic_cast<libtorrent::peer_blocked_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__peer_blocked_alert;
          } else if (dynamic_cast<libtorrent::piece_finished_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__piece_finished_alert;
          } else if (dynamic_cast<libtorrent::portmap_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__portmap_alert;
          } else if (dynamic_cast<libtorrent::portmap_error_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__portmap_error_alert;
          } else if (dynamic_cast<libtorrent::scrape_failed_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__scrape_failed_alert;
          } else if (dynamic_cast<libtorrent::scrape_reply_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__scrape_reply_alert;
          } else if (dynamic_cast<libtorrent::storage_moved_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__storage_moved_alert;
          } else if (dynamic_cast<libtorrent::torrent_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__torrent_alert;
          } else if (dynamic_cast<libtorrent::torrent_checked_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__torrent_checked_alert;
          } else if (dynamic_cast<libtorrent::torrent_deleted_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__torrent_deleted_alert;
          } else if (dynamic_cast<libtorrent::torrent_paused_alert*>(ptr)) {
            swig_type = SWIGTYPE_p_libtorrent__torrent_paused_alert;
          }


          if (swig_type) {
            VALUE obj = SWIG_NewPointerObj(ptr, swig_type, 0);
            if (obj != Qnil) rb_ary_push(array, obj);
          }
        }

        return array;
      }
    }

  };
}

