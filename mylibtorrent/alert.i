%{
#include "libtorrent/alert.hpp"
#include "libtorrent/alert_types.hpp"
%}

namespace libtorrent {

  class peer_id;
  class peer_request;
  class torrent_handle;

  %nodefaultctor alert;
  class alert
  {
  public:

    %rename("DEBUG") debug;
    %rename("INFO") info;
    %rename("WARNING") warning;
    %rename("CRITICAL") critical;
    %rename("FATAL") fatal;
    %rename("NONE") none;
    enum severity_t { debug, info, warning, critical, fatal, none };

    /*boost::posix_time::ptime timestamp() const;*/
    %rename("message") msg() const;
    const std::string& msg() const;
    severity_t severity() const;
  };

  %nodefaultctor torrent_alert;
  struct torrent_alert: alert
  {
    torrent_handle handle;
  };

  struct tracker_alert: torrent_alert
  {
    tracker_alert(torrent_handle const& h
      , int times
      , int status
      , std::string const& url_
      , std::string const& msg)
      : torrent_alert(h, alert::warning, msg)
      , times_in_row(times)
      , status_code(status)
      , url(url_);

    int times_in_row;
    int status_code;
    std::string url;
  };

  struct tracker_warning_alert: torrent_alert
  {
    tracker_warning_alert(torrent_handle const& h
      , std::string const& msg)
      : torrent_alert(h, alert::warning, msg);
  };

  struct scrape_reply_alert: torrent_alert
  {
    scrape_reply_alert(torrent_handle const& h
      , int incomplete_
      , int complete_
      , std::string const& msg)
      : torrent_alert(h, alert::info, msg)
      , incomplete(incomplete_)
      , complete(complete_);

    int incomplete;
    int complete;
  };

  struct scrape_failed_alert: torrent_alert
  {
    scrape_failed_alert(torrent_handle const& h
      , std::string const& msg)
      : torrent_alert(h, alert::warning, msg);
  };

  struct tracker_reply_alert: torrent_alert
  {
    tracker_reply_alert(torrent_handle const& h
      , int np
      , std::string const& msg)
      : alert(h, alert::info, msg)
      , num_peers(np);

    int num_peers;
  };

  struct tracker_announce_alert: torrent_alert
  {
    tracker_announce_alert(torrent_handle const& h, std::string const& msg)
      : torrent_alert(h, alert::info, msg);
  };
  
  struct hash_failed_alert: torrent_alert
  {
    hash_failed_alert(
      torrent_handle const& h
      , int index
      , std::string const& msg)
      : torrent_alert(h, alert::info, msg)
      , piece_index(index);

    int piece_index;
  };

  struct peer_ban_alert: torrent_alert
  {
    peer_ban_alert(asio::ip::tcp::endpoint const& pip, torrent_handle h, std::string const& msg)
      : torrent_alert(h, alert::info, msg)
      , ip(pip);

    asio::ip::tcp::endpoint ip;
  };

  struct peer_error_alert: alert
  {
    peer_error_alert(asio::ip::tcp::endpoint const& pip, peer_id const& pid_, std::string const& msg)
      : alert(alert::debug, msg)
      , ip(pip)
      , pid(pid_);

    asio::ip::tcp::endpoint ip;
    peer_id pid;
  };

  struct invalid_request_alert: torrent_alert
  {
    invalid_request_alert(
      peer_request const& r
      , torrent_handle const& h
      , asio::ip::tcp::endpoint const& sender
      , peer_id const& pid_
      , std::string const& msg)
      : torrent_alert(h, alert::debug, msg)
      , ip(sender)
      , request(r)
      , pid(pid_);

    asio::ip::tcp::endpoint ip;
    peer_request request;
    peer_id pid;
  };

  struct torrent_finished_alert: torrent_alert
  {
    torrent_finished_alert(
      const torrent_handle& h
      , const std::string& msg)
      : torrent_alert(h, alert::warning, msg);

  };

  struct piece_finished_alert: torrent_alert
  {
    piece_finished_alert(
      const torrent_handle& h
      , int piece_num
      , const std::string& msg)
      : torrent_alert(h, alert::debug, msg)
      , piece_index(piece_num);

    int piece_index;

  };

  struct block_finished_alert: torrent_alert
  {
    block_finished_alert(
      const torrent_handle& h
      , int block_num
      , int piece_num
      , const std::string& msg)
      : torrent_alert(h, alert::debug, msg)
      , block_index(block_num)
      , piece_index(piece_num);

    int block_index;
    int piece_index;

  };

  struct block_downloading_alert: torrent_alert
  {
    block_downloading_alert(
      const torrent_handle& h
      , char const* speedmsg
      , int block_num
      , int piece_num
      , const std::string& msg)
      : torrent_alert(h, alert::debug, msg)
      , peer_speedmsg(speedmsg)
      , block_index(block_num)
      , piece_index(piece_num);

    std::string peer_speedmsg;
    int block_index;
    int piece_index;

  };

  struct storage_moved_alert: torrent_alert
  {
    storage_moved_alert(torrent_handle const& h, std::string const& path)
      : torrent_alert(h, alert::warning, path);
  
  };

  struct torrent_deleted_alert: torrent_alert
  {
    torrent_deleted_alert(torrent_handle const& h, std::string const& msg)
      : torrent_alert(h, alert::warning, msg);
  };

  struct torrent_paused_alert: torrent_alert
  {
    torrent_paused_alert(torrent_handle const& h, std::string const& msg)
      : torrent_alert(h, alert::warning, msg);
  };

  struct torrent_checked_alert: torrent_alert
  {
    torrent_checked_alert(torrent_handle const& h, std::string const& msg)
      : torrent_alert(h, alert::info, msg);
  };


  struct url_seed_alert: torrent_alert
  {
    url_seed_alert(
      torrent_handle const& h
      , const std::string& url_
      , const std::string& msg)
      : torrent_alert(h, alert::warning, msg)
      , url(url_);

    std::string url;
  };

  struct file_error_alert: torrent_alert
  {
    file_error_alert(
      const torrent_handle& h
      , const std::string& msg)
      : torrent_alert(h, alert::fatal, msg);
  };

  struct metadata_failed_alert: torrent_alert
  {
    metadata_failed_alert(
      const torrent_handle& h
      , const std::string& msg)
      : torrent_alert(h, alert::info, msg);
  };
  
  struct metadata_received_alert: torrent_alert
  {
    metadata_received_alert(
      const torrent_handle& h
      , const std::string& msg)
      : torrent_alert(h, alert::info, msg);
  };

  struct listen_failed_alert: alert
  {
    listen_failed_alert(
      asio::ip::tcp::endpoint const& ep
      , std::string const& msg)
      : alert(alert::fatal, msg)
      , endpoint(ep);

    asio::ip::tcp::endpoint endpoint;
  };

  struct listen_succeeded_alert: alert
  {
    listen_succeeded_alert(
      asio::ip::tcp::endpoint const& ep
      , std::string const& msg)
      : alert(alert::fatal, msg)
      , endpoint(ep);

    asio::ip::tcp::endpoint endpoint;
  };

  struct portmap_error_alert: alert
  {
    portmap_error_alert(const std::string& msg)
      : alert(alert::warning, msg);
  };

  struct portmap_alert: alert
  {
    portmap_alert(const std::string& msg)
      : alert(alert::info, msg);
  };

  struct fastresume_rejected_alert: torrent_alert
  {
    fastresume_rejected_alert(torrent_handle const& h
      , std::string const& msg)
      : torrent_alert(h, alert::warning, msg);
  };

  struct peer_blocked_alert: alert
  {
    peer_blocked_alert(asio::ip::address const& ip_
      , std::string const& msg)
      : alert(alert::info, msg)
      , ip(ip_);
    
    asio::ip::address ip;
  };
}
