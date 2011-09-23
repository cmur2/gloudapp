
require 'gtk2'
require 'cloudapp_api'

require 'gloudapp/info'
require 'gloudapp/patches'

module GloudApp
	SCRN_TIME_FMT = '%d%m%y-%H%M%S'
	TMP_DIR = "/tmp"

	class App
		def initialize
			@client = CloudApp::Client.new

			login!

			create_tray
		end

		def run!
			@tray.run!
			Gtk.main
		end

		def login!
			if ARGV.length == 2
				# assume that's username and password in ARGV
				@credentials = {:username => ARGV[0], :password => ARGV[1]}
				@client.authenticate(@credentials[:username], @credentials[:password])
				return if credentials_valid?
				ErrorDialog.run!("GloudApp - Error", "Authentication failed!")
				exit 1
			end

			@credentials = load_credentials('.gloudapp')
			if not @credentials.nil?
				@client.authenticate(@credentials[:username], @credentials[:password])
				return if credentials_valid?
			end

			@credentials = load_credentials('.cloudapp-cli')
			if not @credentials.nil?
				@client.authenticate(@credentials[:username], @credentials[:password])
				return if credentials_valid?
			end

			@credentials = request_credentials
			if not @credentials.nil?
				@client.authenticate(@credentials[:username], @credentials[:password])
				return if credentials_valid?
			end
			ErrorDialog.run!("GloudApp - Error", "Authentication failed!")
			exit 1
		end

		def credentials_valid?
			# check whether auth was successful
			@acc = CloudApp::Account.find
			$domain = @acc.domain.nil? ? 'cl.ly' : @acc.domain
			return true
		rescue
			return false
		end

		def load_credentials(name)
			config_file = File.join(ENV['HOME'], name)
			if File.exists?(config_file)
				return YAML.load_file(config_file)
			end
			nil
		end

		def request_credentials
			login_dlg = LoginDialog.new
			case login_dlg.run
			when Gtk::Dialog::RESPONSE_ACCEPT
				creds = {:username => login_dlg.login.text, :password => login_dlg.password.text}
				login_dlg.destroy
				return creds
			when Gtk::Dialog::RESPONSE_REJECT
				login_dlg.destroy
				return nil
			end
		end

		def create_tray
			@tray = Tray.new :default => Proc.new { take_screenshot }

			@tray.add_action "Copy last drop url",
				:show => Proc.new { |item| check_last_drop(item) },
				:action => Proc.new { copy_last_drop_url },
				:no_icon_change => true

			@tray.add_separator

			# take and upload screenshot
			@tray.add_action("Take screenshot") { take_screenshot }

			# upload file from path in clipboard
			@tray.add_action "Upload from clipboard",
				:show => Proc.new { |item| check_clipboard(item) },
				:action => Proc.new { upload_from_clipboard }

			# upload file via file chooser
			@tray.add_action("Upload file") { upload_via_chooser }

			# show about dialog
			@tray.add_action("About", :no_icon_change => true) { GloudApp::AboutDialog.run! }

			@tray.add_separator

			# quit app
			@tray.add_action("Quit", :no_icon_change => true) { Gtk.main_quit }
		end

		def check_clipboard(item)
			with_clipboard_text do |text|
				if !text.nil? and File.file?(text)
					item.set_sensitive(true)
					item.label = "Upload: #{text}"
				else
					item.set_sensitive(false)
					item.label = "Upload from clipboard"
				end
			end
		end

		def upload_from_clipboard
			# current cliboard context might not be the same as shown
			# on popup menu creation...
			with_clipboard_text do |text|
				if !text.nil?
					puts "Uploading file from clipboard..."
					upload_file(text)
				end
			end
		end

		def check_last_drop(item)
			if @last_drop.nil?
				item.set_sensitive(false)
				item.label = "Copy last drop url"
			else
				item.set_sensitive(true)
				item.label = "Copy #{@last_drop.url}"
			end
		end
		
		def copy_last_drop_url
			self.clipboard_text = @last_drop.url unless @last_drop.nil?
		end

		def with_clipboard_text
			Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD).request_text do |clipboard, text|
				yield text
			end
		end
		
		def clipboard_text=(text)
			Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD).text = text
		end

		def upload_via_chooser
			file_dlg = Gtk::FileChooserDialog.new(
				"Upload File", 
				nil, 
				Gtk::FileChooser::ACTION_OPEN, 
				nil,
				[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
				["Upload", Gtk::Dialog::RESPONSE_ACCEPT])
			
			if file_dlg.run == Gtk::Dialog::RESPONSE_ACCEPT
				file = GLib.filename_to_utf8(file_dlg.filename)
				file_dlg.destroy

				# timeout to close file chooser before blocking gtk thread
				Gtk.timeout_add 50 do
					if upload_file(file)
						@tray.icon = Icon.finish
					end
					false
				end
				false
			else
				file_dlg.destroy
				@tray.icon = Icon.normal
				false
			end
		end

		def upload_file(file)
			if File.file?(file)
				puts "Uploading #{file}"
				drop = @client.upload(file)
				puts "URL (in clipboard, too): #{drop.url}"
				# copy URL to clipboard
				self.clipboard_text = drop.url
				@last_drop = drop
				drop.url
			else
				error "Error uploading file #{file}. Does not exists or is not a file."
			end
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
				error "Error taking screenshot - did you install imagemagick?"
			end
		end

		def error(message)
			options = {:message => message} unless message.is_a?(Hash)
			options = {:title => 'GloudApp - Error'}.merge(options)

			@tray.icon = Icon.error
			@tray.message = options[:message]
			ErrorDialog.run!(options[:title], options[:message])
			false
		end
	end
  
	class Icon
		def self.icon(icon) File.join(File.dirname(__FILE__), 'gloudapp', 'icons', icon + '.png') end
		def self.normal_path; self.icon 'gloudapp' end
		def self.finish_path; self.icon 'gloudapp_finish' end
		def self.working_path; self.icon 'gloudapp_working' end
		def self.error_path; self.icon 'gloudapp_error' end
		def self.normal; Gdk::Pixbuf.new(normal_path) end
		def self.finish; Gdk::Pixbuf.new(finish_path) end
		def self.working; Gdk::Pixbuf.new(working_path) end
		def self.error; Gdk::Pixbuf.new(error_path) end
	end
	
	class Tray
		def initialize(options = {}, &default)
			@options = {:tooltip => 'GloudApp', :icon => GloudApp::Icon.normal_path}.merge(options)
			@options[:default] = default unless @options[:default].is_a?(Proc)
		end

		def add_action(title, options = {}, &proc)
			@actions ||= []
			options = {} unless options.is_a?(Hash)
			options[:action] = proc unless options[:action].is_a?(Proc)
			options[:title] = title unless options[:title].is_a?(String)
			@actions << options
		end

		def add_separator()
			@actions ||= []
			@actions << {:separator => true}
		end

		def run!
			@si = Gtk::StatusIcon.new
			@si.pixbuf = Gdk::Pixbuf.new(@options[:icon])
			@si.tooltip = @options[:tooltip]
			@si.signal_connect('activate') do
				run_action @options[:default]
			end

			create_menu
			@si.signal_connect('popup-menu') do |tray, button, time|
				if not @working
					@actions.each do |action|
						if action[:show].is_a?(Proc)
							action[:show].call(action[:item])
						end
					end
					self.icon = Icon.normal
					self.message = nil
					@menu.popup(nil, nil, button, time)
				end
			end
		end

		def icon=(icon)
			@si.pixbuf = icon.is_a?(Gdk::Pixbuf) ? icon : Gdk::Pixbuf.new(icon)
		end

		def message=(message)
			@si.tooltip = message.nil? ? @options[:tooltip] : message.to_s
		end

		private
		def run_action(proc, no_icon_change = false)
			if proc.is_a?(Proc)
				self.icon = Icon.working unless no_icon_change

				# timeout action to get at least on repaint event after
				# changing icon to working image
				Gtk.timeout_add 50 do
					if proc.call
						self.icon = Icon.finish unless no_icon_change
					end
					false
				end
			end
		end

		def create_menu
			@menu = Gtk::Menu.new
			@actions.each do |action|
				if action[:separator]
					@menu.append Gtk::SeparatorMenuItem.new
					next
				end

				item = Gtk::MenuItem.new(action[:title].to_s)
				action[:item] = item
				item.signal_connect('activate') do
					run_action action[:action], !!action[:no_icon_change]
				end
				@menu.append item
			end
			@menu.show_all
		end
	end

	class ErrorDialog < Gtk::MessageDialog
		def initialize(title, message)
			super(nil,
				Gtk::Dialog::MODAL, 
				Gtk::MessageDialog::ERROR,
				Gtk::MessageDialog::BUTTONS_CLOSE, 
				message)
			self.icon = GloudApp::Icon.normal
			self.title = title
		end

		def self.run!(title, message)
			instance = self.new(title, message)
			instance.run
			instance.destroy
		end
	end
	
	class AboutDialog < Gtk::AboutDialog
		def initialize
			super
			self.icon = GloudApp::Icon.normal
			self.name = "GloudApp"
			self.program_name = "GloudApp"
			self.version = GloudApp::Info::VERSION
			self.copyright = GloudApp::Info::COPYRIGHT
			self.license = GloudApp::Info::LICENSE
			self.artists = GloudApp::Info::ARTISTS.map { |author| "#{author[0]} <#{author[1]}>" }
			self.authors = GloudApp::Info::AUTHORS.map { |author| "#{author[0]} <#{author[1]}>" }
			self.website = GloudApp::Info::HOMEPAGE
			self.logo = GloudApp::Icon.normal
		end
		
		def self.run!
			instance = self.new
			instance.run
			instance.destroy
		end
  end

  class LoginDialog < Gtk::Dialog
		attr_reader :login, :password

		def initialize
			super("Authentication",
				nil,
				Gtk::Dialog::MODAL,
				["Login", Gtk::Dialog::RESPONSE_ACCEPT],
				[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
			self.icon = GloudApp::Icon.normal
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
end
