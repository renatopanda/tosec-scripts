require 'nokogiri'
require 'filesize'
require 'byebug'

if ARGV.length == 1
	dats_folder = ARGV[0]
else
	puts "Usage: ruby tosecstatistics.rb [packfolder]"
	puts "Example: ruby tosecstatistics.rb newpack/"
	exit 1
end

class String
  def to_path(end_slash=false)
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}#{'/' if end_slash}" 
  end 
end

dats_folder = dats_folder.to_path(true)

stats = {}
stats['main'] = {}
stats['iso'] = {}
stats['pix'] = {}
stats['total'] = {}

stats['main']['dats'] = 0
stats['main']['sets'] = 0
stats['main']['roms'] = 0
stats['main']['size'] = 0 

stats['iso']['dats'] = 0
stats['iso']['sets'] = 0
stats['iso']['roms'] = 0
stats['iso']['size'] = 0 

stats['pix']['dats'] = 0
stats['pix']['sets'] = 0
stats['pix']['roms'] = 0
stats['pix']['size'] = 0 

datfiles_tosec = Dir.glob(File.join(dats_folder, "TOSEC", "**", "*.dat"))
stats['main']['dats'] = datfiles_tosec.count

datfiles_iso = Dir.glob(File.join(dats_folder, "TOSEC-ISO", "**", "*.dat"))
stats['iso']['dats'] = datfiles_iso.count 

datfiles_pix = Dir.glob(File.join(dats_folder, "TOSEC-PIX", "**", "*.dat"))
stats['pix']['dats'] = datfiles_pix.count 

datfiles = datfiles_tosec + datfiles_iso + datfiles_pix 

datfiles.each do | dat_path | 
	xml_file = File.read(dat_path)
	doc = Nokogiri::XML.parse(xml_file)
	if (dat_path.include?("/TOSEC/"))
		keyvalue = "main"
	elsif (dat_path.include?("/TOSEC-ISO/"))
		keyvalue = "iso"
	elsif (dat_path.include?("/TOSEC-PIX/"))
		keyvalue = "pix"
	else
		keyvalue = "unk?"
	end

	stats[keyvalue]['sets'] += doc.xpath("/datafile/game").count
	stats[keyvalue]['roms'] += doc.xpath("/datafile/game/rom").count
	stats[keyvalue]['size'] += doc.xpath("sum(/datafile/game/rom/@size)")
	#dat_size = Filesize.from("#{stats[keyvalue]['size']} B").pretty
	puts "#{File.basename(dat_path)}: sets=#{stats[keyvalue]['sets']} / roms=#{stats[keyvalue]['roms']} / size=#{Filesize.from("#{doc.xpath("sum(/datafile/game/rom/@size)")} B").pretty} / size[SI]=#{Filesize.new("#{doc.xpath("sum(/datafile/game/rom/@size)")} B", Filesize::SI).pretty}"
	#byebug
end

stats['total']['dats'] = stats['main']['dats'] + stats['iso']['dats'] + stats['pix']['dats']
stats['total']['sets'] = stats['main']['sets'] + stats['iso']['sets'] + stats['pix']['sets']
stats['total']['roms'] = stats['main']['roms'] + stats['iso']['roms'] + stats['pix']['roms']
stats['total']['size'] = stats['main']['size'] + stats['iso']['size'] + stats['pix']['size']

puts "\n\n-------------------------------------------"
puts "----------- Datfiles Statistics -----------"
puts "-------------------------------------------"
stats.each do | key, value |
	puts "-TOSEC-#{key}--------------------------------"
	puts "Datfiles: #{stats["#{key}"]['dats']}"
	puts "Setfiles: #{stats["#{key}"]['sets']}"
	puts "Romfiles: #{stats["#{key}"]['roms']}"
	puts "Size: #{Filesize.from("#{stats[key]['size']} B").pretty} (#{stats["#{key}"]['size']} bytes)"
	puts "Size: #{Filesize.new("#{stats[key]['size']} B", Filesize::SI).pretty} (#{stats["#{key}"]['size']} bytes)"
	puts "-------------------------------------------"
end
