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

def load_file(dir, file)
	k = {}
	File.open(dir + file, "r") {|f|
		while (line = f.gets)
			line.strip!
			next if line =~ /^#/
			next if line =~ /^$/
			if line =~ /^include *(.*)$/
				 k.merge!(load_file(dir, $1))
			elsif line =~ /^([^ ]*) 0x([^ ]*)(.*)$/
				name = $1
				scancode = $2
				mods = $3.split(" ") & ["shift", "altgr", "control"]
				k[name] = [ scancode, mods ]
			end
		end
	}
	k
end

dir = "/usr/share/qemu/keymaps/"

filenames = { "US" => "en-us", "FR" => "fr" }

puts "KEYMAPS = {"
filenames.each{|k,f|
	puts " \"#{k}\" => {"
	map = load_file(dir, f)
	map.keys.sort.each{|name|
		puts "  \"#{name}\" => #{map[name].inspect},"
	}
	puts " },"
}
puts "}"
