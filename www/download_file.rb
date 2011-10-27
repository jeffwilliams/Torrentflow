require 'cgi'
require 'functions'
require 'Mime'

#
# This file returns a download for the specified file.
# It is implemented as a CGI script rather than an eRuby script 
# so that we have control over the Content-Type header.

# This page expects the request to contain the path= form variable

path = nil
Apache.request.paramtable.each{ |k,v|
  k.untaint
  if k == 'path'
    path = v.to_s
  end
}

request = Apache.request
cgi = CGI.new

if ! path 
  # User didn't pass the CGI variable we wanted
  print cgi.header(
    "status" => "BAD_REQUEST",
    "type" => "text/plain"
  )
else
  client = createDaemonClient{ |err|
    errorMessage = err
  }
  if client
    if ! sessionIsValid?(client, Apache.request)
      client.close
      client = nil
      errorMessage = "Your session has expired, or you need to log in"
      print cgi.header(
        "status" => "AUTH_REQUIRED",
        "type" => "text/plain"
      )
    end
  end

  if client
    # Download file

    mimeType = Mime.instance.getMimeTypeOfFilename(File.basename(path))
    mimeType = "application/octet-stream" if ! mimeType
 
    request.sync = true   
    rc = client.downloadFile(path, $stdout){ |length|
      print cgi.header(
        "status" => "OK",
        "type" => mimeType,
        "Content-Disposition" => "inline; filename=#{File.basename(path)}",
        "length" => length
      )
    }

    if ! rc
      # May or may not be too late to set the HTTP status code
      print cgi.header(
        "status" => "SERVER_ERROR"
      )
    end
  end
end
