GloudApp
========

GloudApp is a [CloudApp](http://getcloudapp.com/) client for Linux and
[GNOME2](http://www.gnome.org/) based on GTK using the
[Ruby-GNOME2](http://ruby-gnome2.sourceforge.jp/) bindings.

It is the equivalent to the official OSX client allowing you
to take and upload screenshots with only a single click and
other files through a file chooser dialog.

**[Works with regenwolken](https://github.com/posativ/regenwolken)**

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
do not add rubygem binaries to PATH)

### Ubuntu and AppIndicator (experimental)

People using newer versions of Ubuntu don't see the StatusIcon of GloudApp anymore.
To solve this you should install the libappindicator header files:

	sudo apt-get install libappindicator-dev

And then the [ruby-libappindicator bindings as a gem](https://github.com/leander256/ruby-libappindicator):

	gem install ruby-libappindicator

Note: be beware that this is an experimental feature and that the bindings are stated
as 'beta' by their author.

Usage
-----

You could launch gloudapp (or place it in auto-start) via:

	gloudapp
	
If this does not work and you are not using rvm think about using it. If you 
really do not want to use rvm you may have to add rubygem binaries to your 
PATH by adding `/var/lib/gems/1.8/bin` (depending on your system) to your PATH,
e.g. for Ubuntu 11.04 (into *~/.profile*):

	PATH="$PATH:/var/lib/gems/1.8/bin"

You will be prompted to enter your credentials (or not if you're already
using [cloudapp-cli](https://github.com/cmur2/cloudapp-cli) on the same machine).
A successful login gives you a new small but fine icon right in your notification bar
which is sensitive for left clicking (take screenshot and upload) and right clicking
(offering a popup menu with all other commands). After an upload the new URL
gets copied to the clipboard automatically for easily pasting it somewhere.
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
