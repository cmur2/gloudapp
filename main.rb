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

def take_screenshot
	file = File.join(TMP_DIR, "Screenshot #{Time.now.strftime(SCRN_TIME_FMT)}.png")
	puts "Taking screenshot..."
	# TODO: find rubish way to take screen shots
	# make screenshot via image magick:
	system("import -window root \"#{file}\"")
	upload_file(file)
end

def show_error_dialog(title, msg)
	err_dlg = Gtk::MessageDialog.new(
		nil, Gtk::Dialog::MODAL, Gtk::MessageDialog::ERROR,
		Gtk::MessageDialog::BUTTONS_CLOSE, msg)
	err_dlg.title = title
	err_dlg.run
	err_dlg.destroy
end

# create status icon
si = Gtk::StatusIcon.new
si.pixbuf = Gdk::Pixbuf.new('gloudapp.png')
si.tooltip = 'GloudApp'

# left click
si.signal_connect('activate') do
	take_screenshot
end

# popup menu
screen = Gtk::MenuItem.new("Take screenshot")
screen.signal_connect('activate') do
	take_screenshot
end

@upload = Gtk::MenuItem.new("Upload form clipboard")
@upload.set_sensitive(false)

upload_g = Gtk::MenuItem.new("Upload...")
upload_g.signal_connect('activate') do
	file_dlg = Gtk::FileChooserDialog.new(
		"Upload File", nil, Gtk::FileChooser::ACTION_OPEN, nil,
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
		["Upload", Gtk::Dialog::RESPONSE_ACCEPT])
	if file_dlg.run == Gtk::Dialog::RESPONSE_ACCEPT
		file = GLib.filename_to_utf8(file_dlg.filename)
		file_dlg.destroy
		if File.file?(file)
			upload_file(file)
		else
			show_error_dialog("Error", "Error uploading file #{file}.")
		end
	else
		file_dlg.destroy
	end
end

info = Gtk::MenuItem.new("About")
info.signal_connect('activate') do
	about_dlg = Gtk::AboutDialog.new
	about_dlg.name = "GloudApp"
	about_dlg.program_name = "GloudApp"
	about_dlg.version = "0.1"
	about_dlg.copyright = "Copyright 2011 Christian Nicolai"
	about_dlg.license = "" # TODO: license
	about_dlg.artists = ["Jan Graichen"]
	about_dlg.authors = ["Christian Nicolai"]
	about_dlg.website = "https://github.com/cmur2/gloudapp"
	about_dlg.logo = Gdk::Pixbuf.new('gloudapp.png')
	about_dlg.run
	about_dlg.destroy
end

quit = Gtk::MenuItem.new("Quit")
quit.signal_connect('activate') do
	Gtk.main_quit
end

menu = Gtk::Menu.new
menu.append(screen)
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
					show_error_dialog("Error", "Error uploading file #{file}.")
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

# main
#p Gtk::MAJOR_VERSION, Gtk::MINOR_VERSION, Gtk::MICRO_VERSION

@client = CloudApp::Client.new

if ARGV.length == 2
	# assume that's username and password in ARGV
	@client.authenticate(ARGV[0], ARGV[1])
else
	login_dlg = Gtk::Dialog.new(
		"Authentication", nil, Gtk::Dialog::MODAL,
		["Login", Gtk::Dialog::RESPONSE_ACCEPT],
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
	login_dlg.has_separator = false
	
	login = Gtk::Entry.new
	password = Gtk::Entry.new
	table = Gtk::Table.new(2, 3)
	table.border_width = 5
	image = Gtk::Image.new(Gtk::Stock::DIALOG_AUTHENTICATION, Gtk::IconSize::DIALOG)
	table.attach(image, 0, 1, 0, 2, nil, nil, 10, 10)
	table.attach_defaults(Gtk::Label.new("Username:").set_xalign(1).set_xpad(5), 1, 2, 0, 1)
	table.attach_defaults(login, 2, 3, 0, 1)
	table.attach_defaults(Gtk::Label.new("Password:").set_xalign(1).set_xpad(5), 1, 2, 1, 2)
	password.visibility = false
	table.attach_defaults(password, 2, 3, 1, 2)
	login_dlg.vbox.add(table)
	
#	call_login = Proc.new do |obj, ev|
#		if #(ev.is_a? Gdk::EventKey and (ev.keyval == Gdk::Keyval::GDK_KP_Enter or ev.keyval == Gdk::Keyval::GDK_Return)) or
#			(ev.is_a? Fixnum and ev == Gtk::Dialog::RESPONSE_ACCEPT)
#			@client.authenticate(login.text, password.text)
#		end
#	end
	
	login_dlg.signal_connect("key_release_event") do |obj, ev|
		obj.response(Gtk::Dialog::RESPONSE_ACCEPT) if (ev.is_a? Gdk::EventKey and (ev.keyval == Gdk::Keyval::GDK_KP_Enter or ev.keyval == Gdk::Keyval::GDK_Return))
	end
	#login_dlg.signal_connect('response', &call_login)
	
	login_dlg.show_all
	
	res = login_dlg.run
	if res == Gtk::Dialog::RESPONSE_ACCEPT
		@client.authenticate(login.text, password.text)
		login_dlg.destroy
	elsif res == Gtk::Dialog::RESPONSE_REJECT
		login_dlg.destroy
		exit 1
	end
end

# check whether auth was successful
begin
	@acc = CloudApp::Account.find
	$domain = @acc.domain.nil? ? 'cl.ly' : @acc.domain
rescue
	show_error_dialog("Error", "Authentication failed: #{$!.to_s}")
	exit 1
end

# main loop
Gtk.main
