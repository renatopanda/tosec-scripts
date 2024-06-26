require 'nokogiri'
require 'digest'
require 'byebug'

class String
  def to_path(end_slash=false)
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}#{'/' if end_slash}" 
  end 
end

if ARGV.length == 2
	dats_folder = ARGV[0].to_path(true)
	cues_folder = ARGV[1].to_path(true)
else
	puts "Usage: ruby cuechecker.rb [datsfolder] [cuesbasefolder]"
	puts "Example: ruby cuechecker.rb newpack/TOSEC-ISO/ newpack/CUEs/"
	exit 1
end

#load companies
companies = {}
xml_file = File.read("tosec-scripts/TOSEC Systems XML.xml")
doc = Nokogiri::XML.parse(xml_file)
doc.xpath("/companies/company").each do |company|
	companies[company.xpath("name").text] = []
	company.xpath("systems/system/name").each do | system |
		companies[company.xpath("name").text] << system.text
	end
 end

#systems -> company / split_system division
systems = {}
doc.xpath("/companies/company").each do |company|
	company.xpath("systems/system/name").each do | system |
		systems[system.text] = {}
		systems[system.text]["company"] = company.xpath("name").text
		systems[system.text]["system"] = system.text[systems[system.text]["company"].length+1..-1]
	end
 end

#puts systems["3DO 3DO Interactive Multiplayer"]

# read dats to find existent cues
dat_cues = {}
cue_paths = [] # list of folders expected to exist (based on existing dats)
needed_cues = [] # list of cues needed by the dats
needed_cues_sha1 = [] # list of cues' sha1 hashes

datfiles = Dir["#{dats_folder}*.dat"]
datfiles.each do | file_path |

	xml_file = File.read(file_path)
	doc = Nokogiri::XML.parse(xml_file)

	dat_name = file_path.split("/").last
	system_name = dat_name.split(" - ").first
	#puts dat_name

	if dat_name.start_with?("Multi-format -")
		puts "Multiformat dats (no system) currently unsupported..."
		puts "Skipping: #{dat_name}"
		next #skip this iteration
	end

	dat_cues[dat_name] = {}
	if systems[system_name].nil?
		puts "System missing from Systems XML list: #{dat_name}"
	end
	dat_cues[dat_name]["path"] = [ systems[system_name]["company"], systems[system_name]["system"], dat_name.split(" (TOSEC-v").first.split(" - ")[1..-1] ].join("/")
	dat_cues[dat_name]["cues"] = []
	cue_paths << dat_cues[dat_name]["path"]
	#dat_cues["NEW/3DO 3DO Interactive Multiplayer - Applications - [IMG] (TOSEC-v2017-09-15_CM).dat"] = doc.xpath("/datafile/game/rom[substring(@name,string-length(@name) - 3)='.cue' or substring(@name,string-length(@name) - 3)='.dvd']/@name")

	doc.xpath("/datafile/game/rom[substring(@name,string-length(@name) - 3)='.cue' or substring(@name,string-length(@name) - 3)='.dvd']/@name").each do |rom_name|
		dat_cues[dat_name]["cues"] << rom_name.text
		needed_cues << "#{dat_cues[dat_name]["path"]}/#{rom_name.text}"
		needed_cues_sha1 << rom_name.parent['sha1']
		# byebug 
	 end

end

# get list of existing cues
existing_cues = Dir.glob(File.join(cues_folder, "**","*.cue")) + Dir.glob(File.join(cues_folder, "**","*.dvd"))

existing_cues_sha1 = existing_cues.map{|x| Digest::SHA1.file(x).to_s}

# remove cues_folder base path from each path
existing_cues.map!{|x| x[cues_folder.length..-1]}

# we now have:
# list of paths supposed to exist and contain dats: dat_paths
# list of dats and the cues contained in it (with paths and all)
# list of systems and system paths
# list of existing cues

# I can simply check the differences between existent and needed cues:
missing_cues = needed_cues - existing_cues
unneeded_cues = existing_cues - needed_cues 
missing_cues_sha1 = needed_cues_sha1 - existing_cues_sha1
missing_cues_by_sha1 = missing_cues_sha1.map{ |x| needed_cues[needed_cues_sha1.index(x)]}

#byebug
needed_cue_folders = needed_cues.map { |x| x.split("/")[0..-2].join("/") }.uniq
existing_cue_folders = existing_cues.map { |x| x.split("/")[0..-2].join("/") }.uniq

missing_cue_folders = needed_cue_folders - existing_cue_folders
uneeded_cue_folders = existing_cue_folders - needed_cue_folders 

puts "-------------------------------"
puts "CUE files missing from CUE folder (based on dats):"
puts missing_cues
puts "-------------------------------"
puts "-------------------------------"
puts "CUE files missing based on sha1 (needed - existing):"
missing_cues_by_sha1.each_with_index do | element, index |
	puts "#{element} (sha1: #{needed_cues_sha1[index]})"
end
puts "-------------------------------"
puts "-------------------------------"
puts "CUE files in folder but not used in dats:"
puts unneeded_cues
puts "-------------------------------"
puts "-------------------------------"
puts "Folders/Dats completely missing CUEs:"
puts missing_cue_folders
puts "-------------------------------"
puts "-------------------------------"
puts "Folders (w/ CUEs) no longer needed (no dat present):"
puts uneeded_cue_folders
puts "-------------------------------"
puts "Summary:"
puts "CUEs found in dats: #{needed_cues.count}."
puts "CUEs missing from dats: #{missing_cues.count}."
puts "CUEs missing with wrong sha1: #{missing_cues_by_sha1.count}."
puts "CUEs found in folders: #{existing_cues.count}."
puts "CUEs found but unneeded: #{unneeded_cues.count}."