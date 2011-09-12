#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'gtk2'
require 'cloudapp_api'

SCRN_TIME_FMT = '%d%m%y-%H%M%S'
TMP_DIR = "/tmp"

# patches for cloudapp_api
module CloudApp
	class Account
		attr_reader :subscription_expires_at
	end

	class Drop
		def slug
			url.split(/\//).last
		end

		def self.find(id)
			res = get "http://#{$domain}/#{id}"
			res.ok? ? Drop.new(res) : bad_response(res)
		end

		attr_reader :source
	end

	class Multipart
		def payload
			{
				:headers => {
					"User-Agent"   => "Ruby.CloudApp.API",
					"Content-Type" => "multipart/form-data; boundary=#{boundary}"},
				:body => @body
			}
		end
	end
end

def upload_file(file)
	puts "Uploading #{file}"
	
	drop = @client.upload(file)
	
	puts "URL (in clipboard, too): #{drop.url}"
	
	# copy URL to clipboard
	cb = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
	cb.text = drop.url
end

# main

@client = CloudApp::Client.new

if ARGV.length == 2
	# assume that's username and password in ARGV
	@client.authenticate(ARGV[0], ARGV[1])
else
	# TODO: launch an Gtk Dialog asking for login
	puts "You should provide username and password as arguments!"
	exit 1
end

# check whether auth was successful
begin
	@acc = CloudApp::Account.find
	$domain = @acc.domain.nil? ? 'cl.ly' : @acc.domain
rescue
	abort "Auhtentication failed: #{$!.to_s}"
end

# create status icon
si = Gtk::StatusIcon.new
si.stock = Gtk::Stock::DIALOG_INFO
#si.pixbuf = Gdk::Pixbuf.new('/path/to/image')
si.tooltip = 'GloudApp'

# left click
si.signal_connect('activate') do
	file = File.join(TMP_DIR, "Screenshot #{Time.now.strftime(SCRN_TIME_FMT)}.png")
	puts "Taking screenshot..."
	# TODO: find rubish way to take screen shots
	# make screenshot via image magick:
	system("import -window root \"#{file}\"")
	upload_file(file)
end

# popup menu
@upload = Gtk::MenuItem.new("Upload form clipboard")
@upload.set_sensitive(false)

upload_g = Gtk::MenuItem.new("Upload...")
upload_g.signal_connect('activate') do
	dialog = Gtk::FileChooserDialog.new(
		"Upload File", nil, Gtk::FileChooser::ACTION_OPEN, nil,
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
		[Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
	if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
		file = dialog.filename
		if File.file?(file)
			upload_file(file)
		else
			# TODO: nice dialog
		end
	end
	dialog.destroy
end

info = Gtk::MenuItem.new("About")
info.signal_connect('activate') do
	# TODO: show information dialog
end

quit = Gtk::MenuItem.new("Quit")
quit.signal_connect('activate') do
	Gtk.main_quit
end

menu = Gtk::Menu.new
menu.append(@upload)
menu.append(upload_g)
menu.append(info)
menu.append(Gtk::SeparatorMenuItem.new)
menu.append(quit)
menu.show_all

# show on right click
si.signal_connect('popup-menu') do |tray, button, time|

	cb = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
	cb.request_text do |clipboard, text|
		if !text.nil? and File.file?(text)
			@upload.set_sensitive(true)
			@upload.label = "Upload: #{text}"
			@upload.signal_handler_disconnect(@last_handler) if not @last_handler.nil?
			@last_handler = @upload.signal_connect('activate') do
				puts "Uploading file from clipboard..."
				if File.file?(text)
					upload_file(text)
				else
					# TODO: nice dialog
				end
			end
		else
			@upload.set_sensitive(false)
			@upload.label = "Upload from clipboard"
		end
		menu.popup(nil, nil, button, time)
	end
	
end

#si.signal_connect('query-tooltip') do |tray, x, y, mode, tt| tt = "#{Time.now}" end

# main loop
Gtk.main
