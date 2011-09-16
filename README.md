GloudApp
========

GloudApp is a [CloudApp](http://getcloudapp.com/) client for Linux and
[GNOME2](http://www.gnome.org/) based on GTK using the
[Ruby-GNOME2](http://ruby-gnome2.sourceforge.jp/) bindings.

It hat equivalent features as the official OSX client allowing you
to take and upload screenshots with only a single click and other
files through a file chooser dialog.

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

Usage
-----

You could manually launch the main script (or place it in auto-start) via:

	ruby main.rb

Then you will be prompted to provide your credentials (or not if you're already
using [cloudapp-cli](https://github.com/cmur2/cloudapp-cli) on the same machine).
A successful login gives you a new small but fine icon right in your notification bar
which is sensitive for left clicking (take screenshot and upload) and right clicking
(offering a popup menu with all other commands). After an upload the new URL will
appear immediately be copied into the clipboard for easily pasting it somewhere.
Have fun!

Thanks
------

To [Jan Graichen](https://github.com/jgraichen) for all kinds of help especially his nice art work!

Links
-----

- [no screenshots from Ruby :(](http://tips.webdesign10.com/how-to-take-a-screenshot-on-ubuntu-linux)
- [Ruby-GNOME2](http://ruby-gnome2.sourceforge.jp/)
