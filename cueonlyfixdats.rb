require 'nokogiri'

if ARGV.length == 1
	fixdats_folder = ARGV[0]
else
	puts "Usage: ruby cueonlyfixdats.rb [fixdats_folder]"
	puts "Example: ruby cueonlyfixdats.rb fixdats/"
	exit 1
end

datfiles = Dir["#{fixdats_folder}*.dat"]

datfiles.each do | file_path |

	puts "Checking #{file_path}"
	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)

	non_cue_roms = doc.xpath("/datafile/game/rom[substring(@name,string-length(@name) - 3)!='.cue' and substring(@name,string-length(@name) - 3)!='.dvd']")
	non_cue_roms.remove()

	now_empty_games = doc.xpath("/datafile/game[count(rom)=0]")
	now_empty_games.remove()

	remaining_games = doc.xpath("count(/datafile/game)")

	if (remaining_games==0)
		File.delete(file_path)
	else
		doc.xpath('//text()').find_all {|t| t.to_s.strip == ''}.map(&:remove) # to remove empty lines?
		File.write(file_path, doc.to_xml)
	end

end
