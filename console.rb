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

require 'keyboard'
require 'ttclient'
require 'gtk2'

class Console
	include Keyboard

	def initialize(client)
		@client = client
	end

	def get_console(force=false)
		path = "/cgi/scrtxtdump"
		if (force)
			path += "?force=1"
		end
		res = @client.get(path)
		s = res.body
		return @data unless s
		w = s[12]
		h = s[16]
		x = s[22]
		y = s[20]
		i = 1
		data = ""
		attrs = ""
		s[24..-1].each_byte{|b|
			if i%2 != 0
				data += b.chr
			else
				attrs += b.chr
			end
			i+=1
		}
		attrs = attrs.unpack("a#{w}" * h)
		data = data.unpack("a#{w}" * h)
		data = data.map{|line| cp437_to_utf8(line)}
		if (@w != w || @h != h || @data != data || @attrs != attrs || @x != x || @y != y)
			@w = w
			@h = h
			@x = x
			@y = y
			update_data(data, attrs)
			@buffer.place_cursor(@textview.get_iter_at_location(x, y))
		end	
	end

	def send_key(scancodes, mods={})
		k = scancodes
		if (mods["alt"] && !k.include?("38"))
			k.unshift("38")
		end
		if (mods["control"] && !k.include?("1d"))
			k.unshift("1d")
		end
		if (mods["shift"] && !k.include?("2a"))
			k.unshift("2a")
		end
		k += k.reverse.map{|c| (c.to_i(16)|0x80).to_s(16)}.find_all{|c| c != "e0"}
		p k
		res = @client.post("/cgi/bin", "<RMCSEQ><REQ CMD=\"keybsend\"><KEYS>#{k.join(" ")} </KEYS></REQ></RMCSEQ>")
		p res.body
	end

	def cp437_to_utf8(str)
		map = [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,36,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,199,252,233,226,228,224,229,231,234,235,232,239,238,236,196,197,201,230,198,244,246,242,251,249,255,214,220,162,163,165,8359,402,225,237,243,250,241,209,170,186,191,8976,172,189,188,161,171,187,9617,9618,9619,9474,9508,9569,9570,9558,9557,9571,9553,9559,9565,9564,9563,9488,9492,9524,9516,9500,9472,9532,9566,9567,9562,9556,9577,9574,9568,9552,9580,9575,9576,9572,9573,9561,9560,9554,9555,9579,9578,9496,9484,9608,9604,9612,9616,9600,945,223,915,960,931,963,181,964,934,920,937,948,8734,966,949,8745,8801,177,8805,8804,8992,8993,247,8776,176,8729,183,8730,8319,178,9632,160 ]
		o = str.bytes.map{|b| map[b] }
		return o.pack("U*")
	end

	def update_data(data, attrs)
#		puts "Data is now #{data}"
		@data = data
		@buffer.text = @data.join("\n")
		@buffer.apply_tag("fixed", @buffer.start_iter, @buffer.end_iter)
		i = 0
		@attrs = attrs
		@attrs.each{|l|
			c = 0
			l.each_byte{|b|
				bg = (b & (0x7<<4)) >> 4
				fg = b & 0x7
				start = @buffer.get_iter_at_line_offset(i, c)
				fin = @buffer.get_iter_at_line_offset(i, c+1)
				@buffer.apply_tag(@bgcolortag[bg], start, fin)
				@buffer.apply_tag(@fgcolortag[fg], start, fin)
				if b & 0x8 != 0
					@buffer.apply_tag("bold", start, fin)
				end
				c += 1
			}
			i += 1
		}
	end

	def connect_console
		return if @running == true
		@w = @h = @x = @y = 0
		@data = ""
		window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
		window.signal_connect('delete_event') { @running = false, window.destroy }
		vbox = Gtk::VBox.new
		hbox = Gtk::HBox.new(true, 5)
		shift = Gtk::ToggleButton.new("Shift")
		hbox.add(shift)
		ctrl = Gtk::ToggleButton.new("Ctrl")
		hbox.add(ctrl)
		alt = Gtk::ToggleButton.new("Alt")
		hbox.add(alt)
		vbox.add(hbox)
		@textview = Gtk::TextView.new
		@textview.editable = false
		@textview.modify_cursor(Gdk::Color.parse("white"),Gdk::Color.parse("red"))
		@buffer = @textview.buffer
		@buffer.create_tag("fixed", {"family" => "Monospace"})
		@buffer.create_tag("bold", {"weight" => Pango::FontDescription::WEIGHT_BOLD})
		colors = ["black", "blue", "green", "cyan", "red", "magenta", "yellow", "white"]
		@fgcolortag = []
		(0..7).each{ |i| @fgcolortag[i] = @buffer.create_tag("fgcolor#{i}", { "foreground" => colors[i] })}
		@bgcolortag = []
		(0..7).each{ |i| @bgcolortag[i] = @buffer.create_tag("bgcolor#{i}", { "background" => colors[i] })}
		vbox.add(@textview)
		window.add(vbox)
		get_console(true)
		Gtk.timeout_add(10000){ get_console; @running }
		window.signal_connect("key-release-event") {|w,e|
			puts Gdk::Keyval::to_name(e.keyval)
			mods = {}
			if (ctrl.active? || (e.state.to_i & Gdk::Window::CONTROL_MASK) != 0)
				mods["control"] = true
			end
			if (alt.active? || (e.state.to_i & Gdk::Window::MOD1_MASK) != 0)
				mods["alt"] = true
			end
			if (shift.active? || (e.state.to_i & Gdk::Window::SHIFT_MASK) != 0)
				mods["shift"] = true
			end
			p mods
			Gtk.idle_add() {
				send_key(gdk_keyval_to_scancodes(e.keyval), mods)
				get_console(true)
				false
			}
		}
		@running = true
		window.show_all
	end

end
