# usage example datcheck.rb newpack/TOSEC/
if ARGV.length == 1
	dats_folder = ARGV[0]
else
	puts "Usage: ruby datcheck.rb [dats_folder]"
	puts "Example: ruby datcheck.rb newpack/TOSEC/"
	exit 1
end

require "fileutils"
dir = FileUtils.makedirs "outdated"

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

duplicated = 0
problems = 0 

datfiles.each do | dat |
	#puts "Datfile: #{dat}"
	filename = File.basename(dat)
	idx = filename.index("(TOSEC-")
	partname = filename[0..idx+6]
	found = Dir["#{folder}#{escape_glob(partname)}*.dat"]
	if found.length > 1
		duplicated = duplicated + 1
		puts "-------------------------"
		puts "Found unremoved updates:"
		found.each {|f| puts File.basename f}
		found_sorted = found.sort.reverse!
		found_sorted.delete_at(0)
		FileUtils.mv found_sorted, dir
		puts "Moved files:"
		found_sorted.each { |f| puts f}
		puts "-------------------------"
	end

	# check for possible problem of dat (tosec) where dat - another category (tosec) exists
	partname = filename[0..idx-1]
	#puts partname
	found = Dir["#{folder}#{escape_glob(partname)}-*.dat"]
	#puts "#{folder}#{escape_glob(partname)}-*.dat"
	#puts found
	if (found.length >= 1)
		problems = problems + 1
		puts "Possible problem with a category placed inside a terminal category"
		found.each {|f| puts File.basename f}
	end
end

puts "Moved #{duplicated} datfiles."
puts "Possible problems: #{problems}."
