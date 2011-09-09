#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'gtk2'
require 'cloudapp_api'

$tmp_dir = "/tmp"

@client = CloudApp::Client.new

# all following commands need authentication
@client.authenticate("me", "there")
begin
	@acc = CloudApp::Account.find
	#$domain = @acc.domain.nil? ? 'cl.ly' : @acc.domain
rescue
	abort "Auhtentication failed: #{$!.to_s}"
end

si = Gtk::StatusIcon.new
si.stock = Gtk::Stock::DIALOG_INFO
#si.pixbuf = Gdk::Pixbuf.new('/path/to/image')
si.tooltip = 'GloudApp'

# left click
si.signal_connect('activate') do
	p "Taking a screenshot... (hopefully)"
	file = File.join($tmp_dir, "bam.png")
	system("import -window root -resize 500 #{file}")
	drop = @client.upload file
	p drop.url
end

# popup menu
info = Gtk::ImageMenuItem.new(Gtk::Stock::INFO)
info.signal_connect('activate') do
	#p "Embedded: #{si.embedded?}"; p "Visible: #{si.visible?}"; p "Blinking: #{si.blinking?}"
end

quit = Gtk::ImageMenuItem.new(Gtk::Stock::QUIT)
quit.signal_connect('activate') do
	Gtk.main_quit
end

menu = Gtk::Menu.new
menu.append(info)
menu.append(Gtk::SeparatorMenuItem.new)
menu.append(quit)
menu.show_all

# show on right click
si.signal_connect('popup-menu') do |tray, button, time| menu.popup(nil, nil, button, time) end

# main loop
Gtk.main
