GloudApp
========

Setup
-----

Header files needed to build native gem extensions
(distribution specific package names; here: Ubuntu 11.04):

- libgdk-pixbuf2.0-dev
- libglib2.0-dev
- libatk1.0-dev
- libgtk2.0-dev
- libpango1.0-dev

Then install the gems:

	sudo gem install gtk2 cloudapp_api

On Ruby 1.8 you need json gem, too:

	sudo gem install json

(If you use [rvm](http://beginrescueend.com/) you should omit the 'sudo'.)
