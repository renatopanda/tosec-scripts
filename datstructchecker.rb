require 'nokogiri'
require 'date'
require "fileutils"
require 'byebug'

# usage example datcheck.rb newpack/TOSEC/
if ARGV.length == 1
	dats_folder = ARGV[0]
else
	puts "Usage: ruby datstructcheck.rb [dats_folder]"
	puts "Example: ruby datstructcheck.rb newpack/TOSEC/"
	exit 1
end

dir = FileUtils.makedirs "needsfixing"

ARGV.each do|a|
  puts "Argument: #{a}"
end

if ARGV.length > 0
	folder = ARGV[0]
else
	folder = ""
end


def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
end

datfiles = Dir["#{folder}*.dat"]

tosec_categories = ["TOSEC", "TOSEC-ISO", "TOSEC-PIX"]

# ATT: Nokogiri XXE vuln, this should be used with caution.
options = Nokogiri::XML::ParseOptions::DTDLOAD | Nokogiri::XML::ParseOptions::DTDVALID

datfiles.each do | file_path |

	#puts "------"

	#puts "Checking structure of #{file_path}:"

	xml_file = File.read(file_path)

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

    if (dat_errors_log.size > 1)
    	puts dat_errors_log
    	FileUtils.mv file_path, dir.first
    	puts "Moved to " + File.join(dir.first, File.basename(file_path))
    	puts "-----------------"

    end

    #byebug

end
