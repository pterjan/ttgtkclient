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
require 'gtk2'

class RemoteControl
	COMMANDS = {
		"Shutdown" => ["powerdown", "graceshutdown"],
		"Power Up" => ["powerup"],
		"Power Cycle" => ["powercycle", "gracepowercycle"],
		"Reboot" => ["hardreset", "gracereboot"]
	}	

	def initialize(client)
		@client = client
	end

	def serveraction(action)
		@client.post("/cgi/bin", "<RMCSEQ><REQ CMD=\"serveraction\"><ACT>#{action}</ACT></REQ></RMCSEQ>")
	end

	def display_menu
		dialog = Gtk::Dialog.new("Select an action",
					nil,
					nil,
					[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_NONE ],
					[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT ])
		cb = Gtk::ComboBox.new
		COMMANDS.keys.each{|k|
			cb.append_text(k)
		}
		cb.active = 0
		gracefulbutton = Gtk::CheckButton.new("Graceful")
		cb.signal_connect('changed') {
			gracefulbutton.sensitive = COMMANDS[cb.active_text].length == 2
		}
		dialog.vbox.add(cb)
		dialog.vbox.add(gracefulbutton)
		dialog.resizable = false
		dialog.show_all
		dialog.run { |response|
			if response == Gtk::Dialog::RESPONSE_ACCEPT
				actions = COMMANDS[cb.active_text]
				action = actions[0]
				if actions.length == 2 && gracefulbutton.active?
					action = actions[1]
				end
				serveraction(action)
  			end
		}
		dialog.destroy
	end

end
