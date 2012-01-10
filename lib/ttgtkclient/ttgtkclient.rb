#
# Client for HP P1218A TopTools Remote Control
#
# Copyright (c) 2011-2012 Pascal Terjan <pterjan@gmail.com>
#               All Rights Reserved
#
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

require 'ttclient'
require 'console'
require 'control'

class TTGtkClient
	def initialize
		create_client
		display_menu
	end

	def create_client
		dialog = Gtk::Dialog.new("Connection Parameters",
					nil,
					nil,
					[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT ])
		table = Gtk::Table.new(3,2)
		column_spacings = 6
		server_label = Gtk::Label.new("Server")
		server_entry = Gtk::Entry.new
		server_entry.text = "127.0.0.1:80"
		server_label.mnemonic_widget = server_entry
		table.attach(server_label, 0, 1, 0, 1, Gtk::FILL, Gtk::FILL, 3, 3)
		table.attach(server_entry, 1, 2, 0, 1, Gtk::EXPAND, Gtk::FILL, 3, 3)
		user_label = Gtk::Label.new("User")
		user_entry = Gtk::Entry.new
		user_entry.text = "ADMIN"
		user_label.mnemonic_widget = user_entry
		table.attach(user_label, 0, 1, 1, 2, Gtk::FILL, Gtk::FILL, 3, 3)
		table.attach(user_entry, 1, 2, 1, 2, Gtk::EXPAND, Gtk::FILL, 3, 3)
		pass_label = Gtk::Label.new("Password")
		pass_entry = Gtk::Entry.new
		pass_entry.visibility = false
		pass_label.mnemonic_widget = pass_entry
		pass_entry.signal_connect('activate'){ dialog.response(Gtk::Dialog::RESPONSE_ACCEPT) }
		table.attach(pass_label, 0, 1, 2, 3, Gtk::FILL, Gtk::FILL, 3, 3)
		table.attach(pass_entry, 1, 2, 2, 3, Gtk::EXPAND, Gtk::FILL, 3, 3)
		dialog.vbox.add(table)
		dialog.resizable = false
		dialog.show_all
		dialog.run { |response|
			if response == Gtk::Dialog::RESPONSE_ACCEPT
				@client = TTClient.new(server_entry.text)
				@client.do_login(user_entry.text, pass_entry.text)
				dialog.destroy
    			else
				exit
  			end
		}
	end

	def connect_console
		@console = Console.new(@client) unless @console
		@console.connect_console
	end

	def display_info(window)
		dialog = Gtk::Dialog.new("Server Information",
					window,
					nil,
					[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT ])
		info = @client.get_info
		table = Gtk::Table.new(info.keys.length, 2)
		i = 0
		info.each{|k,v|
			label1 = Gtk::Label.new.set_markup("<b>#{k}</b>")
			label1.selectable = true
			label2 = Gtk::Label.new(v)
			label2.selectable = true
			table.attach(label1, 0, 1, i, i+1, Gtk::FILL, Gtk::FILL, 3, 3)
			table.attach(label2, 1, 2, i, i+1, Gtk::FILL, Gtk::FILL, 3, 3)
			i += 1
		}
		dialog.vbox.add(table)
		dialog.resizable = false
		dialog.show_all
		dialog.run
		dialog.destroy
	end

	def display_menu
		window = Gtk::Window.new("TTGtkClient")
		window.window_position = Gtk::Window::POS_CENTER_ALWAYS
		window.signal_connect('delete_event') { Gtk.main_quit }
		vbox = Gtk::VBox.new
		info = Gtk::Button.new("Server Info")
		info.signal_connect('released') { display_info(window) }
		vbox.add(info)
		console = Gtk::Button.new("Console")
		console.signal_connect('released') { connect_console }
		vbox.add(console)
		rc = Gtk::Button.new("Remote Control")
		rc.signal_connect('released') { RemoteControl.new(@client).display_menu }
		vbox.add(rc)
		quit = Gtk::Button.new("Quit")
		quit.signal_connect('released') { Gtk.main_quit }
		vbox.add(quit)
		window.add(vbox)
		window.show_all
		Gtk.main
	end
end
