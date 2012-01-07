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

require 'base64'
require 'digest/md5'
require 'net/http'

class TTClient
	def initialize(server, sid=nil)
		@server = server
		@cookie = "sid=#{sid}" if sid
		@data = ""
		@attrs = ""
	end

	def crc16(str)
		k = 0
		str.each_byte{|b|
			k ^= b << 8
			8.times{
				if (k & 0x8000) == 0x8000 then
					k = k << 1 ^ 0x1021
				else
					k <<= 1
				end
			}
		}
		k &= 0xffff
		return k
	end

	def encode_pass(challenge, pass)
		challenge = Base64.decode64(challenge)
		pass_md5 = Digest::MD5.digest(pass)

		res = (0..pass_md5.length-1).map{|i| x=i % 16; (challenge[x] ^ pass_md5[x]).chr }.join
		res_md5 = Digest::MD5.digest(res)
	
		res_crc = crc16(res_md5)
		res_md5 += (res_crc & 0xFF).chr
		res_md5 += ((res_crc / 256) & 0xFF).chr
	
		return Base64.encode64(res_md5)
	end

	def get_challenge
		res = get("/cgi/challenge")
		if res.code != "200" then
			throw "Failed to get challenge"
		end
		@cookie =  res['set-cookie'].split('; ')[0]
		#p @cookie
		xml = res.body
		xml =~ /<RMCLOGIN><CHALLENGE>(.*)<\/CHALLENGE><RC>(.*)</
		return $1
	end

	def do_login(login, pass)
		hash = encode_pass(get_challenge, pass)
		res = get("/cgi/login?user=#{login}&hash=#{hash}")
		if res.code != "200" then
			throw "Failed to login"
		end
		at_exit do
			do_logout
		end
	end

	def do_logout
		get("/cgi/logout")
	end


	def get_props(props)
		proplist = props.map{|p| "<PROP NAME=\"#{p}\"/>"}.join
		res = post('/cgi/bin', "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ><REQ CMD=\"propget\"><PROPLIST>#{proplist}</PROPLIST></REQ></RMCSEQ>")
		# <?xml version='1.0'?><?RMCXML version='1.0'?><RMCSEQ><RESP CMD="propget"><RC>0x0</RC><PROPLIST><PROP NAME="SERVER_KEYBOARD"><PERMS>RW</PERMS><VAL>FR</VAL></PROP><PROP NAME="ENABLE_REMOTE_FLOPPY_BOOT"><PERMS>RW</PERMS><VAL>FALSE</VAL></PROP><PROP NAME="TFTP_ADDR_REBOOT"><PERMS>RW</PERMS><VAL>172.16.0.5</VAL></PROP><PROP NAME="TFTP_REBOOT_FILE"><PERMS>RW</PERMS><VAL>ttrc0304.bin</VAL></PROP><PROP NAME="SERVER_CODEPAGE"><PERMS>RW</PERMS><VAL>850</VAL></PROP></PROPLIST></RESP></RMCSEQ>
		return res.body
	end

	def set_props(props)
		proplist = props.keys.map{|k| "<REQ CMD=\"propset\"><PROP NAME=\"#{k}\"><VAL>#{props[k]}</VAL></PROP></REQ>"}.join
		res = post('/cgi/bin', "<?xml version=\"1.0\"?><?RMCXML version=\"1.0\"?><RMCSEQ>#{proplist}</RMCSEQ>")
		return res.body
	end

	def get_info
		res = get("/cgi/info.txt")
		info = {}
		res.body.each_line{|l|
			if l =~ /([^=]*)=(.*)/
				info[$1] = $2.strip
			end
		}
		info
	end

	def post(path, data)
		uri = URI("http://#{@server}#{path}")
		req = Net::HTTP::Post.new(uri.request_uri)
		req['Cookie'] = @cookie
		return Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req, data) }
	end

	def get(path)
		uri = URI("http://#{@server}#{path}")
		req = Net::HTTP::Get.new(uri.request_uri)
		req['Cookie'] = @cookie
		return Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
	end
end

