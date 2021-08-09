require 'nokogiri'
require 'fileutils'
require 'date'
#require 'byebug'

if ARGV.length == 5
	newfolder = ARGV[0]
	oldfolder = ARGV[2]
	newdate = ARGV[1]
	olddate = ARGV[3]
	branch = ARGV[4]
else
	puts "Usage: ruby relfixdat.rb [newfolder] [newdate] [oldfolder] [olddate] [TOSEC-branch]"
	puts "Example: ruby relfixdat.rb newpack/TOSEC/ 2018-07-27 oldpack/TOSEC/ 2018-04-01 TOSEC"
	exit 1
end

	puts "Generate fixdat of the newly added roms of #{branch} branch"
  	puts "Newer folder: #{newfolder} (from #{newdate})"
  	puts "Older folder: #{oldfolder} (from #{olddate})"

fixdat_version = Date.today.strftime("%Y-%m-%d")
fixdat_name = "#{branch} Update Pack #{olddate} to #{newdate}"
fixdat_description = "#{fixdat_name} (TOSEC-v#{fixdat_version})"
fixdat_filename = "#{fixdat_name} (TOSEC-v#{fixdat_version}_CM).dat"

newpack = Dir["#{newfolder}*.dat"]
oldpack = Dir["#{oldfolder}*.dat"]

oldmd5s = Hash.new
puts "Building map of oldpack roms..."

oldpack.each_with_index do | file_path, index |
	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)
	roms = doc.xpath("/datafile/game/rom/@md5").map{|attr| oldmd5s[attr.value]=1}
	print "\rHashs inserted: #{oldmd5s.size} (datfile #{index+1} of #{oldpack.size})"
end

newdats = (newpack.map{|n| File.basename(n)} - oldpack.map{|n| File.basename(n)}).map{|x| File.join(newfolder, x)}
puts "\nFound #{newdats.size} new datfiles, will check them for new roms"

# create update pack datfile
xml = Nokogiri::XML::Builder.new { |xml| 
    xml.datafile do
    	xml.header do
    		xml.name fixdat_name
    		xml.description fixdat_description
    		xml.version fixdat_version
    		xml.author "panda"
    		xml.email "contact@tosecdev.org"
    		xml.homepage "TOSECdev.org"
    		xml.url "https://www.tosecdev.org"
    	end
    end }.to_xml

fixdat = Nokogiri::XML.parse(xml) { |x| x.noblanks }

added_romnames = Hash.new 
newdats.each_with_index do | file_path, index |
	print "\rParsing datfile #{index+1} of #{newdats.size}"
	systemname = File.basename(file_path).split(" - ").first
	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)
	roms = doc.xpath("/datafile/game/rom")
	roms.each do | cnode |
		if oldmd5s[cnode['md5']].nil?
			# puts "New rom: #{cnode['name']}"
			# get system setfile in the fixdat
			# fix using flexible quoting https://stackoverflow.com/questions/14822153/escape-single-quote-in-xpath-with-nokogiri
			sysnode = fixdat.xpath(%{/datafile/game[@name="#{systemname}"]}).first
			if sysnode.nil? # does not exist yet
				sysnode = Nokogiri::XML::Node.new "game", fixdat
				sysnode['name'] = systemname
				sysdescnode = Nokogiri::XML::Node.new "description", fixdat
				sysdescnode.content = systemname
				sysnode.add_child(sysdescnode)
				fixdat.xpath("/datafile").first.add_child(sysnode)
			end
			# check if a node with similar name was added before
			if !added_romnames["#{systemname}-#{cnode['name']}"].nil?
				i = 1
				romname = cnode['name']
				while (!added_romnames["#{systemname}-#{romname}"].nil?) do
					romname = "#{cnode['name']}_dup#{i}"
					i = i + 1
				end
				cnode['name'] = romname
			end
			added_romnames["#{systemname}-#{cnode['name']}"] = cnode['md5']
			sysnode.add_child(cnode)
		end
	end
	#byebug
end

File.write(fixdat_filename, fixdat.to_xml)
puts "\nFixdat saved to:\n#{fixdat_filename}"