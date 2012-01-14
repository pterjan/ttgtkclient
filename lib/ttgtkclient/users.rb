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

class Users
	def initialize(client)
		@client = client
	end

	def get_list
		users = []
		res = @client.post("/cgi/bin", "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"usrlist\"></REQ></RMCSEQ>")
		if res.body =~ /<USRLIST>(.*)<\/USRLIST>/
			users = $1.scan(/<USER NAME="([^"]*)"\/>/).flatten
		end
		users
	end

	def get_props(user, props=[])
		proplist = props.map{|p| "<PROP NAME=\"#{p}\"/>"}.join
		res = @client.post('/cgi/bin', "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"usrpropget\"><USER NAME=\"#{user}\">#{proplist}</USER></REQ></RMCSEQ>")
		return Hash[res.body.scan(/<PROP NAME="([^"]*)"><PERMS>[^<]*<\/PERMS><VAL>([^<]*)<\/VAL><\/PROP>/)]
	end

	def set_props(user, props)
		proplist = props.keys.map{|k| "<REQ CMD=\"usrpropset\"><USER NAME=\"#{user}\"><PROP NAME=\"#{k}\"><VAL>#{props[k]}</VAL></PROP></USER></REQ>"}.join
p proplist
		res = @client.post('/cgi/bin', "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ>#{proplist}</RMCSEQ>")
p res
		return res.body
	end
end
