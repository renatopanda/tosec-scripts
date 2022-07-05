require "fileutils"
#require 'byebug'
# usage example datcheck.rb newpack/TOSEC/
if ARGV.length == 1
	folder = ARGV[0]
else
	puts "Usage: ruby datcheck.rb [dats_folder]"
	puts "Example: ruby datcheck.rb newpack/TOSEC/"
	exit 1
end

dir = FileUtils.makedirs "outdated"

ARGV.each do|a|
  puts "Argument: #{a}"
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

duplicated = 0
split = 0 

puts "-------------------------"

datfiles.each do | dat |
	#puts "Datfile: #{dat}"
	filename = File.basename(dat)
	idx = filename.index("(TOSEC-")
	partname = filename[0..idx+6]
	found = Dir["#{folder}#{escape_glob(partname)}*.dat"]
	if found.length > 1
		duplicated = duplicated + 1
		puts "Found unremoved updates:"
		found.each {|f| puts File.basename f}
		found_sorted = found.sort.reverse!
		found_sorted.delete_at(0)
		#byebug
		FileUtils.mv found_sorted, dir.first
		puts "Moved datfiles (to #{dir.first}):"
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
		split = split + 1
		puts "Found datfiles (child) whose sets will be placed inside another datafile (father) folder:"
		puts "father: #{filename}"
		found.each {|f| puts "child: #{File.basename f}"}
		#byebug
		FileUtils.mv dat, dir.first # mv needs to receive either 2 strings or 2 arrays
		puts "Moved datfile (to #{dir.first}):"
		puts dat
		puts "-------------------------"
	end
end
puts "-------------------------"
puts "Moved #{duplicated+split} outdated datfiles, of these:"
puts "\t* due to direct updates: #{duplicated}"
puts "\t* due to category reorganizations: #{split}"
