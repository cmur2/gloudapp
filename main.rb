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

class App
	def initialize
		@client = CloudApp::Client.new
		
		if ARGV.length == 2
			# assume that's username and password in ARGV
			@client.authenticate(ARGV[0], ARGV[1])
		else
			login_dlg = LoginDialog.new
			case login_dlg.run
			when Gtk::Dialog::RESPONSE_ACCEPT
				@client.authenticate(login_dlg.login.text, login_dlg.password.text)
				login_dlg.destroy
			when Gtk::Dialog::RESPONSE_REJECT
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
		register_status_icon
		Gtk.main
	end
	
	def register_status_icon
		# status icon
		@si = Gtk::StatusIcon.new
		@si.pixbuf = Gdk::Pixbuf.new('gloudapp.png')
		@si.tooltip = 'GloudApp'
		@si.signal_connect('activate') do
			take_screenshot
		end
		@menu = create_popup_menu
		@si.signal_connect('popup-menu') do |tray, button, time|
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
				@menu.popup(nil, nil, button, time)
			end
		end
	end
	
	def create_popup_menu
		screen = Gtk::MenuItem.new("Take screenshot")
		screen.signal_connect('activate') { take_screenshot }

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
		info.signal_connect('activate') { show_about_dialog }

		quit = Gtk::MenuItem.new("Quit")
		quit.signal_connect('activate') { Gtk.main_quit }

		menu = Gtk::Menu.new
		[screen, @upload, upload_g, info,
			Gtk::SeparatorMenuItem.new, quit].each { |item| menu.append(item) }
		menu.show_all
		menu
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
		if File.file?(file)
			upload_file(file)
		else
			show_error_dialog("Error", "Error taking screenshot - did you install imagemagick?")
		end
	end

	def show_error_dialog(title, msg)
		err_dlg = Gtk::MessageDialog.new(
			nil, Gtk::Dialog::MODAL, Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE, msg)
		err_dlg.title = title
		err_dlg.icon = Gdk::Pixbuf.new('gloudapp.png')
		err_dlg.run
		err_dlg.destroy
	end
	
	def show_about_dialog
		about_dlg = Gtk::AboutDialog.new
		about_dlg.icon = Gdk::Pixbuf.new('gloudapp.png')
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
end

class LoginDialog < Gtk::Dialog
	attr_reader :login, :password

	def initialize
		super("Authentication", nil, Gtk::Dialog::MODAL,
			["Login", Gtk::Dialog::RESPONSE_ACCEPT],
			[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
		self.icon = Gdk::Pixbuf.new('gloudapp.png')
		self.has_separator = false

		@login = Gtk::Entry.new
		@password = Gtk::Entry.new.set_visibility(false)
		image = Gtk::Image.new(Gtk::Stock::DIALOG_AUTHENTICATION, Gtk::IconSize::DIALOG)

		table = Gtk::Table.new(2, 3).set_border_width(5)
		table.attach(image, 0, 1, 0, 2, nil, nil, 10, 10)
		table.attach_defaults(Gtk::Label.new("Username:").set_xalign(1).set_xpad(5), 1, 2, 0, 1)
		table.attach_defaults(@login, 2, 3, 0, 1)
		table.attach_defaults(Gtk::Label.new("Password:").set_xalign(1).set_xpad(5), 1, 2, 1, 2)
		table.attach_defaults(@password, 2, 3, 1, 2)

		self.vbox.add(table)
		self.show_all
		# close dialog on return or enter
		self.signal_connect("key_release_event") do |obj, ev|
			if ev.keyval == Gdk::Keyval::GDK_Return or ev.keyval == Gdk::Keyval::GDK_KP_Enter
				obj.response(Gtk::Dialog::RESPONSE_ACCEPT)
			end
		end
	end
end

App.new
