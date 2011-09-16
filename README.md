GloudApp
========

GloudApp is a [CloudApp](http://getcloudapp.com/) client for Linux and
[GNOME2](http://www.gnome.org/) based on GTK using the
[Ruby-GNOME2](http://ruby-gnome2.sourceforge.jp/) bindings.

It hat equivalent features as the official OSX client allowing you
to take and upload screenshots with only a single click and other
files through a file chooser dialog.

Install
-------

Header files needed to build native gem extensions for gtk2 gem and dependencies
(distribution specific package names; here: Ubuntu 11.04):

	libgdk-pixbuf2.0-dev libglib2.0-dev libatk1.0-dev libgtk2.0-dev libpango1.0-dev

Then install the gloudapp gem:

	gem install gloudapp

If you do not use [rvm](http://beginrescueend.com/) you should add an 'sudo'
but rvm ist strongly recommended because some 
[linux distributions](https://bugs.launchpad.net/ubuntu/+source/gems/+bug/145267) 
does not add rubygem binaries into there PATH)

Usage
-----

You could launch gloudapp (or place it in auto-start) via:

	gloudapp
	
If this does not work and you are not using rvm think about using it. If you 
really do not want to use rvm you may have to add rubygem binaries to your 
PATH by adding `/var/lib/gems/1.8/bin` (depending on your system) to your PATH.

You will be prompted to provide your credentials (or not if you're already
using [cloudapp-cli](https://github.com/cmur2/cloudapp-cli) on the same machine).
A successful login gives you a new small but fine icon right in your notification bar
which is sensitive for left clicking (take screenshot and upload) and right clicking
(offering a popup menu with all other commands). After an upload the new URL will
appear immediately be copied into the clipboard for easily pasting it somewhere.
Have fun!

Thanks
------

To [Jan Graichen](https://github.com/jgraichen) for all kinds of help especially his nice art work!

License
-------

GloudApp is licensed under the Apache License, Version 2.0. See LICENSE for more information.

Links
-----

- [no screenshots from Ruby :(](http://tips.webdesign10.com/how-to-take-a-screenshot-on-ubuntu-linux)
- [Ruby-GNOME2](http://ruby-gnome2.sourceforge.jp/)
