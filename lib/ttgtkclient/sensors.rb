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

class Sensors
	def initialize(client)
		@client = client
	end

	def get_list
		res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"sensorlist\"></REQ></RMCSEQ>")
		if res.body =~ /<HANDLE>(.*)<\/HANDLE><SENSORLIST>(.*)<\/SENSORLIST>/
			@handle = $1
			@keys = $2.scan(/<SENSOR KEY="([^"]*)"\/>/)
		end
	end

	def get_sensors
		get_list unless @keys
		i = 0
		l = []
		while i <= @keys.size/4
			res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"sensorpropget\"><HANDLE>#{@handle}</HANDLE><SENSORLIST>#{@keys[i..(i+4)].map{|k| "<SENSOR KEY=\"#{k}\"/>"}}</SENSORLIST><PROPLIST><PROP NAME=\"ENABLED\"/><PROP NAME=\"SENSOR_TYPE\"/><PROP NAME=\"NAME\"/><PROP NAME=\"GEN_TYPE\"/><PROP NAME=\"VAL\"/><PROP NAME=\"UNITS\"/><PROP NAME=\"SEVERITY\"/></PROPLIST></REQ></RMCSEQ>")
			l += res.body.scan(/<SENSOR KEY="([^"]*)">(.*?)<\/SENSOR>/).map{|l|
				key = l[0]
				props = Hash[l[1].scan(/<PROP NAME="([^"]*)"><VAL>([^<]*)<\/VAL><TYPE>([^<]*)<\/TYPE><\/PROP>/).map{|p|
					name = p[0]
					val = case
					when p[1] == "STRING"
						p[1]
					when p[1] == "INT32"
						p[1].to_i
					when p[1] == "REAL32"
						p[1].to_f
					else
						p[1]
					end
					[ name, val ]
				}]
				[ key, props ]
			}
			i += 1
		end
		Hash[l]
	end

	def display_sensors
		dialog = Gtk::Dialog.new("Sensors",
					nil,
					nil,
					[ Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_CLOSE ])
		model = Gtk::TreeStore.new(String, String)
		sensors = get_sensors
		sensors.keys.sort.each{|k|
			s = sensors[k]
			next unless s["ENABLED"] == "Enabled"
			val = s["VAL"].to_s
			val += " #{s["UNITS"]}" if s["UNITS"]
			siter = model.append(nil).set_value(0, s["NAME"]).set_value(1, val)
		}
		model.set_sort_column_id(0)
		tv = Gtk::TreeView.new(model)
		renderer = Gtk::CellRendererText.new
		column0 = Gtk::TreeViewColumn.new("Name", renderer, :text => 0)
		column1 = Gtk::TreeViewColumn.new("Value", renderer, :text => 1)
		tv.append_column(column0)
		tv.append_column(column1)
		dialog.vbox.add(tv)
		dialog.show_all
		dialog.run
		dialog.destroy
	end
end
