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
require 'date'

class Logs
	def initialize(client)
		@client = client
		get_info
	end

	def parse_date(date)
		DateTime.strptime(date, '%Y%m%d%H%M%S.000000+000')
	end

	def format_date(date)
		date.strftime("%a %b %e %Y %H:%M:%S")
	end

	def get_info
		res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"selgetinfo\"></REQ></RMCSEQ>")
		if res.body =~ /<HANDLE>(.*)<\/HANDLE><ENTRIES>(.*)<\/ENTRIES><ADDTIME>(.*)<\/ADDTIME><ERASETIME>(.*)<\/ERASETIME><SPACE>(.*)<\/SPACE>/
			@handle = $1
			@entries = $2.to_i(16)
			addtime = parse_date($3)
			erasetime = parse_date($4)
			space = $5.to_i(16)
			puts "#{@entries} log entries, #{space} space remaining\nMost recent one added on #{format_date(addtime)}\nLast cleared on #{format_date(erasetime)}"
		end
	end

	def fetch
		logs = []
		remaining = @entries
		num = 0x28
		while remaining > 0
			num = remaining if num > remaining
			offset = remaining - num
			res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"selgetentry\"><HANDLE>#{@handle}</HANDLE><OFFSET>0x#{offset.to_s(16)}</OFFSET><ORDER>0x1</ORDER><NUM>0x#{num.to_s(16)}</NUM></REQ></RMCSEQ>")
			logs += res.body.scan(/<EVENT KEY=\"0x\d*\"><DATETIME>([^<]*)<\/DATETIME><PC>([^<]*)<\/PC><SEV>([^<]*)<\/SEV><STR>([^<]*)<\/STR><SENSOR KEY="([^<]*)"\/><TR>([^<]*)<\/TR><\/EVENT>/)
			remaining -= num
		end
		logs.map{|l|
			{
				:date => parse_date(l[0]),
				:severity => l[2],
				:message => l[3]
			}
		}
	end

	def clear
		@client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"selclear\"></REQ></RMCSEQ>")
	end

	def display_logs
		dialog = Gtk::Dialog.new("Logs",
					nil,
					nil,
					[ Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_CLOSE ])
		logs = fetch
		model = Gtk::TreeStore.new(String, DateTime, String)
		logs.each{|l|
			sev =  Gtk::Stock::DIALOG_QUESTION
			if l[:severity] == "Information"
				sev =  Gtk::Stock::DIALOG_INFO
			else
				puts "Unknown severity #{l[:severity]}"
			end
			iter = model.append(nil)
			iter.set_value(0, sev)
			iter.set_value(1, l[:date])
			iter.set_value(2, l[:message])
		}
		tv = Gtk::TreeView.new(model)
		pixrenderer = Gtk::CellRendererPixbuf.new
		textrenderer = Gtk::CellRendererText.new
		column0 = Gtk::TreeViewColumn.new("Severity", pixrenderer, :stock_id => 0)
		column1 = Gtk::TreeViewColumn.new("Date", textrenderer)
		column1.set_cell_data_func(textrenderer) {|col, renderer, model, iter|
			renderer.text = format_date(iter[1])
		}
		model.set_default_sort_func {|iter1, iter2|
			iter2[1] <=> iter1[1]
		}
		column2 = Gtk::TreeViewColumn.new("Message", textrenderer, :text => 2)
		tv.append_column(column0)
		tv.append_column(column1)
		tv.append_column(column2)
		dialog.vbox.add(tv)
		dialog.show_all
		dialog.run
		dialog.destroy
	end
end
