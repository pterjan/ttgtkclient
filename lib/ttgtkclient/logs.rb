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

class Logs
	def initialize(client)
		@client = client
		get_info
	end

	def get_info
		res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"selgetinfo\"></REQ></RMCSEQ>")
		if res.body =~ /<HANDLE>(.*)<\/HANDLE><ENTRIES>(.*)<\/ENTRIES><ADDTIME>(.*)<\/ADDTIME><ERASETIME>(.*)<\/ERASETIME><SPACE>(.*)<\/SPACE>/
			@handle = $1
			@entries = $2.to_i(16)
			addtime = $3
			erasetime = $4
			space = $5.to_i(16)
			puts "#{@entries} log entries, #{space} space remaining\nMost recent one added on #{addtime}\nLast cleared on #{erasetime}"
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
		logs
	end

	def clear
		@client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"selclear\"></REQ></RMCSEQ>")
	end

end
