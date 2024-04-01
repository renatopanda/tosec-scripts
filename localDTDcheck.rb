require 'nokogiri'
require 'byebug'

# usage example datcheck.rb newpack/TOSEC/
if ARGV.length >= 1
  datfile_path = ARGV[0].strip
  dtd_path = 'tosec-scripts/datafile.dtd'
  if ARGV.length == 2
    dtd_path = ARGV[1].strip
  end
else
  puts "Usage: ruby localDTDcheck.rb <datfile_path> [dtd_path]"
  puts "Example 1: ruby localDTDcheck.rb newpack/TOSEC/dat_abc.dat"
  puts "Example 2: ruby localDTDcheck.rb newpack/TOSEC/dat_abc.dat tosec-script/datafile.dtd"
  exit 1
end

unless File.exists?(datfile_path)
  puts "Error: datfile #{datfile_path} not found!"
  exit 1
end

unless File.exists?(dtd_path)
  puts "Error: DTD file #{dtd_path} not found!"
  exit 1
end

# Load the XML document
xml = File.read(datfile_path)

# Load the DTD file
dtd_string = "<!DOCTYPE datafile SYSTEM \"#{dtd_path}\">"

puts "Will validate #{datfile_path} using local DTD: #{dtd_path}."

# validation using local DTD validation for security and speed (and connection issues)
xml = xml.gsub('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">', dtd_string)

options = Nokogiri::XML::ParseOptions::DTDLOAD | Nokogiri::XML::ParseOptions::DTDVALID

#options = Nokogiri::XML::ParseOptions::DTDVALID

doc = Nokogiri::XML::Document.parse(xml, nil, nil, options)

errors = doc.external_subset.validate(doc)

# Check if any validation errors occurred
if errors.empty?
  puts "Datfile (XML document) is valid."
else
  puts "Datfile (XML document) validation errors:"
  errors.each do |error|
    puts error
  end
end
