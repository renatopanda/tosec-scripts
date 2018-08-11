require 'nokogiri'
require 'fileutils'
require 'date'
require 'json'
#require 'byebug'

if ARGV.length == 1
	folder = ARGV[0]
else
	puts "Usage: ruby hashcollisions.rb [datsfolder]"
	puts "Example: ruby relfixdat.rb newpack/TOSEC/"
	exit 1
end

puts "Checking CRC collisions in folder #{folder}"

pack = Dir["#{folder}*.dat"]

crc32_sha1 = Hash.new
md5s_sha1 = Hash.new
crc32_stats = Hash.new
crc32_collisions = 0


puts "Searching for CRC32 collisions..."

pack.each_with_index do | file_path, index |
	systemname = File.basename(file_path).split(" - ").first

	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)
	roms = doc.xpath("/datafile/game/rom").map do | romnode |
		if crc32_sha1[romnode['crc']].nil?
			crc32_sha1[romnode['crc']] = [romnode['sha1'], romnode['name'], File.basename(file_path), systemname]
		elsif crc32_sha1[romnode['crc']][0] != romnode['sha1']
			crc32_stats[systemname] ||= 0
			crc32_stats[systemname] = crc32_stats[systemname] + 1
			if (File.basename(file_path) != crc32_sha1[romnode['crc']][2])
				if (systemname != crc32_sha1[romnode['crc']][3])
					puts "INTER-system: #{File.basename(file_path)} vs #{crc32_sha1[romnode['crc']][2]}:"
				else
					puts "INTER-dat: #{File.basename(file_path)} vs #{crc32_sha1[romnode['crc']][2]}:"
				end
			else
				puts "INTRA-dat: #{File.basename(file_path)}:"
			end
			puts "crc=\"#{romnode['crc']}\" sha1=\"#{romnode['sha1']}\" rom=\"#{romnode['name']}\""
			puts "crc=\"#{romnode['crc']}\" sha1=\"#{crc32_sha1[romnode['crc']][0]}\" rom=\"#{crc32_sha1[romnode['crc']][1]}\""
			crc32_collisions = crc32_collisions + 1
		end
	end
	#print "\rHashs inserted: #{crc32_sha1.size} (datfile #{index+1} of #{pack.size})"
end

crc32_sha1.clear

md5_collisions = 0

puts "Searching for MD5 collisions..."

pack.each_with_index do | file_path, index |
	#puts file_path
	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)
	roms = doc.xpath("/datafile/game/rom").map do | romnode |
		if md5s_sha1[romnode['md5']].nil?
			md5s_sha1[romnode['md5']] = [romnode['sha1'], romnode['name'], File.basename(file_path)]
		elsif md5s_sha1[romnode['md5']][0] != romnode['sha1']
			if (File.basename(file_path) != md5s_sha1[romnode['md5']][2])
				puts "INTER-dat: #{File.basename(file_path)} vs md5s_sha1['md5'][2]:"
			else
				puts "INTRA-dat: #{File.basename(file_path)}:"
			end
			puts "md5=\"#{romnode['md5']}\" sha1=\"#{romnode['sha1']}\" rom=\"#{romnode['name']}\""
			puts "md5=\"#{romnode['md5']}\" sha1=\"#{md5s_sha1[romnode['md5']][0]}\" rom=\"#{md5s_sha1[romnode['md5']][1]}\""
			md5_collisions = md5_collisions + 1
		end
	end
	#print "\rHashs inserted: #{crc32_sha1.size} (datfile #{index+1} of #{pack.size})"
end

puts "CRC32 collisions found: #{crc32_collisions}"
print JSON.pretty_generate(crc32_stats)
puts "\nMD5 collisions found: #{md5_collisions}"