Warning
=======

Torrentflow is no longer being developed. It has been superceded by [QuartzFlow] (https://github.com/jeffwilliams/quartz-flow).

Torrentflow
===========

Torrentflow is a web-based torrent downloader, inspired by TorrentFlux. It uses Rasterbar's 
libtorrent for managing torrents, and so supports the latest torrent features (such as 
UDP trackers).

Torrentflow consists of a daemon that performs the downloading, and a web application
that acts as the user interface.


Acknowlegements
---------------

Portions of the ruby libtorrent-rasterbar wrapper code is taken from Joshua Bassett's 
libtorrent-ruby package, which was under the BSD license.


Dependencies
------------

Running requires:

  * ruby
  * json rubygem
  * mahoro rubygem
  * sinatra rubygem
  * haml rubygem
  * mongo rubygem (Optional)

Building requires:

  * swig 1.3 (for ruby 1.8) or swig 2.0 (for ruby 1.9)
  * make
  * g++
  * ruby1.8-dev
  * libtorrent-rasterbar-dev, and libtorrent-rasterbar (version 0.14 - 0.16)
  * libasio-dev (if not installed as part of boost)


Installation 
------------

1. Unpack the torrentflow archive to the desired installation path and unpack the archive. 

2. If you downloaded the binary package, install the dependencies for running. If you downloaded the
   source package, install the building and running dependencies (See appendix A for details).

3. In the installation directory run `./install.rb`.

4. Edit the configuration file `etc/torrentflowdeamon.conf` and set appropriate settings for the 
   parameters. 

5. (Optional) Edit the configuration file `etc/sinatra.conf` and set appropriate settings for the 
   parameters. 

6. Add at least one user using `bin/adduser <username>`. 


Running
-------

1. Start the daemon by running `bin/start-daemon`.

2. Start the web application by running `bin/start-sinatra`.

3. Log messages are written to `logs/daemon.log` and `logs/sinatra.log` by default. Check the logfiles 
   for any errors.

4. In your web browser open `http://host:4567/` where host is the server running the appserver. Log in using
   the username created in installation step 4.

5. Stop the daemon and web application using `bin/stop-daemon` and `bin/stop-sinatra`


Building
--------

1. Change to the libtorrent directory and run `./extconf.rb`


Known Issues
------------

The Torrentflow webapp looks terrible in Internet Explorer.


Appendix A: Installing Dependencies
-----------------------------------

To install ruby, g++, make, ruby-dev, libasio-dev, and libtorrent-rasterbar-dev you should use the package management
system of your Linux distribution.

To install the rubygems use the gem tool. For example to install sinatra, use:

`sudo gem install sinatra`


