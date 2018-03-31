# Example snippet to output companies and systems
require 'nokogiri'

xml_file = File.read("TOSEC Systems XML.xml")
doc = Nokogiri::XML.parse(xml_file)
doc.xpath("/companies/company").each do |company|
	# for each company
	company.xpath("systems/system/name").each do | system |
		# for each system...
		puts "Company #{company.xpath("name").text} contains system #{system.text}."
	end
 end

