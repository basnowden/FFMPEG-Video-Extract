#!/usr/bin/env ruby
# Batch encodes videos from a list of editing points
# Original Author: Werner Robitza <werner.robitza@univie.ac.at>
# Modified by: Brady Snowden <bradysnowden@gmail.com>

FFMPEG    = "ffmpeg"    # => path to the FFmpeg executable

OVERWRITE = "-n"  # => set to "-n" if you just want to keep files that exist
                  # => set to "-y" if you want to force overwrite
                  # => set to "" if you want to be asked for each file

INPUT_FORMAT = ".mp4"   # => change this depending on the input format suffix

# CSV options

CSV_COL_SEP = ',' # => CSV column separator
PREFIX      = 0   # => CSV column for a general ID or prefix
VIDEO_INDEX = 1   # => CSV column for the video ID
INPUT_FILE  = 2   # => CSV column for the video input name
IN_INDEX    = 3   # => CSV column for the edit in-point
DIFF_INDEX  = 4   # => CSV column for the duration of edits

EXT       = "mp4"       # => extension for the destination file (e.g. mp4)

# ----------------------------------------------------------------------------
# DO NOT CHANGE ANYTHING BELOW THIS LINE
# ----------------------------------------------------------------------------

if RUBY_VERSION =~ /1\.8[\.\d]*/
  puts "Doesn't work with #{RUBY_VERSION}, needs at least 1.9.2"
  exit
end

require 'csv'

if ARGV.length != 2
  puts "Usage: video-extract.rb <csv> <input> <output>"
  puts "       <csv>    the file with the input data"
  puts "       <output> an output folder for the results"
  exit
end

input_file = ARGV[0]
out_dir = ARGV[1]

if not File.file?(input_file)
  puts "Input CSV file not found or readable" 
  exit
end

if not File.directory?(out_dir)
  puts "Output folder not found or readable" 
  exit
end

# ----------------------------------------------------------------------------

begin
  CSV.foreach(input_file, :col_sep => CSV_COL_SEP) do |row|
    prefix    = row[PREFIX]
    video     = row[VIDEO_INDEX] #Only relevant with multiple source files
    input     = row[INPUT_FILE]
    output    = input.chomp(INPUT_FORMAT)
    inpoint   = row[IN_INDEX]
    diff      = row[DIFF_INDEX]
    begin
      command = "#{FFMPEG} #{OVERWRITE} -ss #{inpoint} -i \"#{input}\" -ss 10.000 -c copy -t #{diff} \"#{out_dir}/#{prefix}-video_#{video}-#{output}.#{EXT}\"" #-ss becomes unsynchronized with large time jumps, so a secondary 10s skip has been added to minimize desync
      puts "--------------------------------------------------------------"
      puts "Command to execute: "
      puts command
      system(command)
	  comm = "echo file '#{out_dir}/#{prefix}-video_#{video}-#{output}.#{EXT}'>>filelist.txt"
	  puts comm
	  system(comm)
    rescue
      puts "Error while executing the command. Skipping to next one."
    end
  end
  command = "#{FFMPEG} -f concat -safe 0 -i filelist.txt -c copy shortened_output.mp4"
  puts command
  system(command)
rescue
  puts "Error while reading CSV file. Exiting."
end
