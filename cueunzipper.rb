# this takes a folder of folders with cues (zipped) as setfiles
# and unzips each one to the parent folder, removing the zip
# It also removes all the empty folders
# 
# This tool serves to sort cues from time to time.
# HowTo:
# 1) Get CMP or RomVault
# 2) Get all ISO datfiles moved to the right folders (scripts mv & create)
# 3) Move the scripts to the datfiles folder
# 4) Open CMP and BATCH REBUILD the datfiles using as source the existing cues (or use RomVault)
# 4.1) Select all dats from cmp profiler (reset folder if needed)
# 4.2) in Rebuild use zip, set source, don't set destiny.
# 4.3) In Misc set folder rompath to folder structure or whatever
# 4.4) Set a rompath default folder (short one) and run
# 4.5) This will rebuild all cues to zips in the right place
# 5) This script picks that folder structure
# 5.1) Unzip all cues from zips to the parent folder
# 5.2) Remove all zips
# 5.3) Remove empty folders created by cmp for dats without cues
# 6) After that, cues are sorted and ready to release but check them (cuechecker.rb)
require 'byebug'
require 'zip'
Zip.on_exists_proc = true 
Zip.unicode_names = true 

if ARGV.length == 1
	cues_folder = ARGV[0]
else
	puts "Usage: ruby cuepreparer.rb [cuesbasefolder]"
	puts "Example: ruby cuepreparer.rb newpack/CUEs/"
	exit 1
end

removed_folders = 0 
unzipped_cues = 0 

zip_files = Dir.glob(File.join(cues_folder, "**","*.zip"))

zip_files.each do | zipped_cue |

	Zip::File.open(zipped_cue) do |zip_file|
	  # Handle entries one by one
	  zip_file.each do |entry|
	  	#byebug
	    # Extract to file/directory/symlink
	    dest_file = File.join(File.dirname(zipped_cue), entry.name).force_encoding(Encoding::UTF_8)
	    puts "Extracting #{zip_file.name}".force_encoding(Encoding::UTF_8)
	    entry.extract(dest_file)
	    unzipped_cues += 1
	  end
	end

	# remove zip, not needed anymore
	File.delete(zipped_cue)
end

# now get all directories, sort by length to delete longer ones first and remove empty ones
existing_dirs = Dir.glob(File.join(cues_folder, "**", "*")).select {|f| File.directory? f} #'certain_directory/**/*/'
existing_dirs = existing_dirs.sort_by(&:length).reverse

existing_dirs.each do | folder_path |
	if Dir.empty?(folder_path)
		puts "Removing empty folder: #{folder_path}"
		Dir.delete(folder_path)
		removed_folders += 1
	end
end

puts "-------------------------------"
puts "CUEs unzipped: #{unzipped_cues}"
puts "Empty folders removed: #{removed_folders}"
puts "-------------------------------"
