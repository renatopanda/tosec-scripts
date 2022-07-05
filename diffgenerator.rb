class String
  def to_path(end_slash=false)
    "#{'/' if self[0]=='\\'}#{self.split('\\').join('/')}#{'/' if end_slash}" 
  end 
end

if ARGV.length == 2
	newfolder = ARGV[0].to_path(true)
	oldfolder = ARGV[1].to_path(true)
else
	puts "Usage: ruby diffgenerator.rb [newfolder] [oldfolder]"
	puts "Example: ruby diffgenerator.rb newpack/TOSEC/ oldpack/TOSEC/"
	exit 1
end

	puts "Generate new/updated/removed between folders."
  	puts "Newer folder: #{newfolder}"
  	puts "Older folder: #{oldfolder}"


def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
end


newdats = Dir["#{newfolder}*.dat"]
olddats = Dir["#{oldfolder}*.dat"]

duplicated = 0
added = Array.new
updated = Array.new
removed = Array.new
problem = Array.new

newdats.each do | dat |
	#puts "Datfile: #{dat}"
	filename = File.basename dat
	idx = filename.index("(TOSEC-")
	partname = filename[0..idx+6]
	#puts partname
	found = Dir["#{oldfolder}#{escape_glob(partname)}*.dat"]
	if found.empty? # the dat does not exist in old folder, it's new!
		added << filename
	elsif found.length == 1 # one found, check if it's the same, updated or some mistake
		if filename != File.basename(found[0])
			newdat_date = filename[idx+7..-9]
			olddat_date = found[0][-19..-9]
			if (newdat_date > olddat_date)
				updated << filename
			else
				problem << filename
				puts "Dat seems outdated!"
				puts dat
				puts found[0]
			end
		end
	elsif found.length > 1
		puts "More equally named dats than expected in the outdated folder?"
		found.each { |f| puts f }
	end
end

# check for removed dats (exist in old, missing in new, excluding updates)
olddats.each do | dat |
	filename = File.basename dat
	idx = filename.index("(TOSEC-")
	partname = filename[0..idx+6]
	#puts "#{escape_glob(partname)}*.dat"
	found = Dir["#{newfolder}#{escape_glob(partname)}*.dat"]
	if found.empty? # the dat does not exist in old folder, it's new!
		removed << filename
	end
end

puts "--------------------"
puts "Added: #{added.length}"
puts "Updated: #{updated.length}"
puts "Removed: #{removed.length}"
puts "Problems: #{problem.length}"
puts "--------------------"

puts "#{newfolder}: #{newdats.length} DATs (#{added.length} new / #{updated.length} updated / #{removed.length} removed)"
puts ""
puts "NEW (#{added.length}):"
added.each { |f| puts f }
puts ""
puts "UPDATED (#{updated.length}):"
updated.each { |f| puts f }
puts ""
puts "REMOVED (#{removed.length}):"
removed.each { |f| puts f }
