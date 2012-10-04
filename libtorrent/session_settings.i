%{
#include "libtorrent/session_settings.hpp"
%}

namespace libtorrent
{
  struct pe_settings
  {
    pe_settings()
      : out_enc_policy(enabled)
      , in_enc_policy(enabled)
      , allowed_enc_level(both)
      , prefer_rc4(false);

    %rename("FORCED") forced;
    %rename("ENABLED") enabled;
    %rename("DISABLED") disabled;
    enum enc_policy
    {
      forced,  // disallow non encrypted connections
      enabled, // allow encrypted and non encrypted connections
      disabled // disallow encrypted connections
    };

    %rename("PLAINTEXT") plaintext;
    %rename("RC4") rc4;
    %rename("BOTH") both;
    enum enc_level
    {
      plaintext, // use only plaintext encryption
      rc4, // use only rc4 encryption 
      both // allow both
    };

    enc_policy out_enc_policy;
    enc_policy in_enc_policy;

    enc_level allowed_enc_level;
    bool prefer_rc4;
  };
}


