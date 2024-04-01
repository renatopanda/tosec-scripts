require 'nokogiri'
require 'date'
require "fileutils"
require 'byebug'

paranoid = 0
local_dtd = 1
dtd_path = 'tosec-scripts/datafile.dtd'

# usage example datcheck.rb newpack/TOSEC/
if ARGV.length >= 1
	dats_folder = ARGV[0]
	if ARGV.length == 2
		paranoid = ARGV[1].to_i
	end
else
	puts "Usage: ruby datstructcheck.rb <dats_folder> [PARANOID]"
	puts "Example: ruby datstructcheck.rb newpack/TOSEC/"
	puts "PARANOID mode:"
	puts "   1 = check set name vs description"
	puts "   2 = check set name vs rom name"
	puts "      - single-rom sets, only for non-empty space sets, avoid mass false reports in dats such as Amiga SPS"
	puts "      - for /TOSEC-ISO/ folders it checks multi-rom sets but ignores ones with (Track x of y) or non-white space rom names"
	puts "   3 = check set name vs rom name (single-rom sets, all)"
	exit 1
end

dir = FileUtils.makedirs "needsfixing"

ARGV.each do |a|
  puts "Argument: #{a}"
end

if (local_dtd)
	puts "DTD validation: local"
else
	puts "DTD validation: external"
end

if ARGV.length > 0
	folder = ARGV[0]
else
	folder = ""
end


def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
end

class String
  def to_path(end_slash=false)
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}#{'/' if end_slash}" 
  end 
end

folder = folder.to_path(true)

datfiles = Dir["#{folder}*.dat"]

puts "Found #{datfiles.size} datfiles in #{folder}..."

tosec_categories = ["TOSEC", "TOSEC-ISO", "TOSEC-PIX"]

# ATT: Nokogiri XXE vuln, this should be used with caution.
options = Nokogiri::XML::ParseOptions::DTDLOAD | Nokogiri::XML::ParseOptions::DTDVALID

datfiles.each do | file_path |

	# puts "------"

	# puts "Checking structure of #{file_path}:"

	xml_file = File.read(file_path)

	if local_dtd
		# Load the DTD file
		dtd_string = "<!DOCTYPE datafile SYSTEM \"#{dtd_path}\">"
		# puts "Will validate #{file_path} using local DTD: #{dtd_path}."
		# validation using local DTD validation for security and speed (and connection issues)
		xml_file = xml_file.gsub('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">', dtd_string)
	end

	#doc = Nokogiri::XML.parse(xml_file)
	doc = Nokogiri::XML::Document.parse(xml_file, nil, nil, options)

	dat_errors_log = ["Checking #{file_path}:"]

	struct_errors = doc.external_subset.validate(doc)
	if (struct_errors.nil? || struct_errors.empty? == false)
		dat_errors_log << "Structural errors found against the DTD."
		dat_errors_log << struct_errors
	end

	#byebug

	dat_category = doc.xpath("datafile/header/category").text
	dat_description = doc.xpath("datafile/header/description").text
	dat_name = doc.xpath("datafile/header/name").text
	dat_version = doc.xpath("datafile/header/version").text

	if (!tosec_categories.include? dat_category)
        dat_errors_log << "category field is incorrect (should be TOSEC, TOSEC-ISO or TOSEC-PIX)"
        dat_errors_log << "datfile/header/category = " + dat_category
    end

    if dat_description != "#{dat_name} (TOSEC-v#{dat_version})"
        dat_errors_log << "description field is different than name + version"
        dat_errors_log << "datfile/header/description = " + dat_description
        dat_errors_log << "datfile/header/name+version= #{dat_name} (TOSEC-v#{dat_version})"
    end

    if dat_version > DateTime.now.strftime('%Y-%m-%d')
    	dat_errors_log << "version is more recent than current day (today)"
    	dat_errors_log << "datfile/header/version = " + dat_version
    end

    filename = File.basename(file_path)

    if filename != "#{dat_name} (TOSEC-v#{dat_version}_CM).dat"
    	dat_errors_log << "dat filename and the filename generated from header info don't match"
    	dat_errors_log << "filename : #{filename}"
    	dat_errors_log << "generated: #{dat_name} (TOSEC-v#{dat_version}_CM).dat"
    end

    begin
    	Date.parse(dat_version)
    rescue ArgumentError => error_msg
    	dat_errors_log << "version/date error: #{error_msg}"
    	dat_errors_log << "datfile/header/version = " + dat_version
    end

    #byebug

    if (paranoid)
	    dat_sets = Hash.new

	    doc.xpath("/datafile/game").each do | game_node |
	    	#puts "#{dat_sets}"
	    	if dat_sets[game_node['name']].nil?
					dat_sets[game_node['name']] = 1
				else
					dat_errors_log << "Sets with duplicated name: #{game_node['name']}."
		    end

		    if (game_node['name'] != game_node.xpath("description").text)
		    	dat_errors_log << "Set name and description don't match:"
		    	dat_errors_log << "SET : #{game_node['name']}."
		    	dat_errors_log << "DESC: #{game_node.xpath("description").text}."
		    end

		    if (paranoid >= 2 && game_node.xpath("rom").size == 1)
		    	rom_name = game_node.xpath("rom").first['name'].rpartition('.').first
		    	if (paranoid == 3 || rom_name.match(" "))
			    	if (game_node['name'] != rom_name)
			    		dat_errors_log << "[PARANOID] Set and rom name (single rom set) don't match:"
			    		dat_errors_log << "SET: #{game_node['name']}"
			    		dat_errors_log << "ROM: #{rom_name}"
			    		dat_errors_log << "---"
			    		#byebug	
			    	end
			    end
			  elsif (paranoid >= 2 && folder.end_with?("/TOSEC-ISO/"))
			  	game_node.xpath("rom").each do | rom |
			  		rom_name = rom['name'].rpartition('.').first
			  		if (game_node['name'] != rom_name && rom_name.match(" ") && rom_name.match("\(Track \\d{1,3} of \\d{1,3}\)").nil?)
			  			dat_errors_log << "[PARANOID] Set and rom name (multi rom set) don't match:"
			    		dat_errors_log << "SET: #{game_node['name']}"
			    		dat_errors_log << "ROM: #{rom_name}"
			    		dat_errors_log << "---"
			  		end
			  	end
		    end
		    #byebug
		  end
		end

	  if (dat_errors_log.size > 1)
    	puts dat_errors_log
    	FileUtils.mv file_path, dir.first
    	puts "Moved to " + File.join(dir.first, File.basename(file_path))
    	puts "-----------------"
    end
end
