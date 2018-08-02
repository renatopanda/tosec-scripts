require 'net/ftp'
require 'io/console'
require "fileutils"
require 'byebug'

$dats = []
$txts = []
$cues = []
$zips = []
$ignored = []
$last_release = "2018-06-20"
$current_path = nil

#unix ftp list regex
$unix_list_regex = /^(?<type>.{1})(?<mode>\S+)\s+(?<number>\d+)\s+(?<owner>\S+)\s+(?<group>\S+)\s+(?<size>\d+)\s+(?<mod_time>.{12})\s+(?<path>.+)$/
$cues_regex = /(\.cue$|\.img$|CUE)/i
$relevantzip_regex = /.*(dat|dats|\(TOSEC-v\d{4}-\d{2}-\d{2}).*\.(zip|rar|7z)$/i

def scan(ftp, dir)
  begin
    puts "Scanning: " + dir + "/."
    #STDOUT.flush
    begin
      ftp.chdir(dir)
      $current_path = ftp.pwd 
      entries = ftp.list('*')
    rescue Net::FTPTempError, Timeout::Error, Net::OpenTimeout, EOFError, Errno::EPIPE, Errno::ECONNRESET => e
      puts "Error during FTP scan (entering/listing): #{e.message}"
      puts "current path: #{$current_path}"
      puts "subdirectory trying to explore: #{dir}"
      sleep 3
      reconnect(ftp)
      ftp.chdir(dir)
      $current_path = ftp.pwd 
      entries = ftp.list('*')
    end
    entries.each do |entry|
      entry_info = entry.match($unix_list_regex)
      #byebug
      if (entry_info[:type] == 'd')
        # puts "dir#{entry_info[:path]}"
        scan(ftp, dir+"/"+entry_info[:path])
      elsif(Date.parse(entry_info[:mod_time])>Date.parse($last_release))
        if (entry_info[:path].end_with?('.dat'))
          #puts "new dat: #{entry_info[:path]}"
          $dats << "#{$current_path}/#{entry_info[:path]}"
        elsif (entry_info[:path].end_with?('.txt'))
          #puts "new txt: #{entry_info[:path]}"
          $txts << "#{$current_path}/#{entry_info[:path]}"
        elsif (entry_info[:path].match($cues_regex).nil? == false)
         # puts "new cuefiles: #{entry_info[:path]}"
          $cues << "#{$current_path}/#{entry_info[:path]}"
        elsif (entry_info[:path].match($relevantzip_regex).nil? == false && entry_info[:size].to_i < 20_000_000)
         # puts "new cuefiles: #{entry_info[:path]}"
          $zips << "#{$current_path}/#{entry_info[:path]}"
        else
          #puts "new file (ignored): #{entry_info[:path]}"
          $ignored << "#{$current_path}/#{entry_info[:path]}"
        end
      end
    end

    begin
      ftp.chdir('..')
    rescue Net::FTPTempError, Timeout::Error, Net::OpenTimeout, EOFError, Errno::EPIPE, Errno::ECONNRESET => e
      puts "Error during FTP scan (exiting folder): #{e.message}"
      puts "current path: #{$current_path}"
      puts "subdirectory trying to explore: #{dir}"
      sleep 3
      reconnect(ftp)
      ftp.chdir(dir)
      $current_path = ftp.pwd 
      ftp.chdir('..')
    end
  rescue Net::FTPPermError => e
    puts "Error during FTP scan: #{e.message}"
    puts "current path: #{$current_path}"
    puts "subdirectory trying to explore: #{dir}"
    puts e.backtrace.inspect
    ftp.chdir('..')
  rescue StandardError => e
    puts e.message
    puts e.backtrace.inspect
    #byebug
  end
end

def reconnect(ftp)
  puts "Reconnecting... (obj.id: #{ftp.object_id})"
  ftp.close
  ftp.connect($server)
  ftp.login($user, $pass)
end

def transfer_files(ftp, files, base_path)
  FileUtils.makedirs files.map {|x| File.dirname(File.join(base_path, x))}.uniq
  files.each do | file |
    puts "Transfering: " + file
    ftp.getbinaryfile(file, File.join(base_path, file))
  end
end

 
# Determine if the user is asking for help.
helpArgs = ["h", "-h", "/h", "?", "-?", "/?"]
if helpArgs.index(ARGV[0]) != nil || ARGV.length < 5 then
  puts <<-eos
------------------------------
TOSECdev FTP WIP dats scanner:
------------------------------
This script recursively scans an ftp directory and returns a list of 
all files relevant* for a new TOSEC release.
*) as in newer than the given last release date

USAGE:
ruby wipftpscan.rb [ftpserver] [username] [password] [last_release] [transfer] [base_remote_folder]

EXAMPLES:
ruby wipftpscan.rb ftp.example.com user passwd 2018-06-20 n
ruby wipftpscan.rb ftp.example.com user passwd 2018-06-20 y
ruby wipftpscan.rb ftp.example.com user passwd 2018-06-20 y uploads/renamers-wip
  eos
else
  $server, $user, $pass, $last_release, batch_transfer, base_remote_folder = ARGV
  $dest_folder = "wip dats"# if $dest_folder.nil?
  base_remote_folder = '/' if base_remote_folder.nil?

  puts <<-eos
TOSECdev FTP WIP dats scanner

This script will scan all FTP folders for relevant dats/cues/txts/archives
FTP: #{$server}
USER: #{$user}
LAST RELEASE DATE: #{$last_release}
FTP BASE FOLDER: #{base_remote_folder}
DEST FOLDER: #{$dest_folder}
    eos

  #STDOUT.sync = true # output to stdout in realtime (no buffering) - slower but can check logs faster
  ftp = Net::FTP.new($server)
  #ftp.passive = true
  ftp.login($user, $pass)
  puts "SERVER INFO: #{ftp.system}"
  #puts ftp.status
  #byebug
  puts "Initializing FTP scan for: #{$server}"
  ftp.chdir(base_remote_folder)
  scan(ftp, ftp.pwd) # to get the full path even if the given base path is relative

  puts <<-eos
FTP scan finished.
Relevant dats: #{$dats.size}
Relevant txts: #{$txts.size}
Relevant cues: #{$cues.size}
Possible relevant zip/rar/7z: #{$zips.size}
Ignored files: #{$ignored.size}
    eos

    puts "NEW DATS:"
    puts $dats

    puts "NEW TXTs:"
    puts $txts

    puts "NEW CUEs:"
    puts $cues

    puts "NEW (Possible relevant) zip/rar/7z files:"
    puts $zips

    puts "IGNORED files:"
    puts $ignored

  user_input = ''
  if (batch_transfer.nil?)
    loop do
      puts "Proceed with transfer of dats/txts/cues? (y/n)"
      
      user_input = STDIN.getc
      break if user_input != "y" || user_input != "n"
    end
  else
    user_input = batch_transfer
  end

  if (user_input == "y")
    puts "\n\nFTP file transfer starting..."
    FileUtils.makedirs $dest_folder

    transfer_files ftp, $dats, File.join($dest_folder, 'dats')
    transfer_files ftp, $txts, File.join($dest_folder, 'txts')
    transfer_files ftp, $cues, File.join($dest_folder, 'cues')
    transfer_files ftp, $zips, File.join($dest_folder, 'zips')
  end
  ftp.close
end


module Net
  class FTP
    def makepasv
      if @sock.peeraddr[0] == 'AF_INET'
        host, port = parse229(sendcmd('EPSV'))
      else
        host, port = parse227(sendcmd('EPSV'))
      end
      return host, port
    end
  end
end





# def is_ftp_file?(ftp, file_name)
#   ftp.chdir(file_name)
#   ftp.chdir('..')
#   false
# rescue
#   true
# end

# def is_ftp_file?(ftp, file_name)
#   begin 
#   if ftp.size(file_name).is_a? Numeric
#       true
#   end
#   rescue Net::FTPPermError
#       return false
#   end
# end