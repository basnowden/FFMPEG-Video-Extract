#!/usr/bin/env ruby
# Batch encodes videos from a list of editing points
# Author: Werner Robitza <werner.robitza@univie.ac.at>

FFMPEG    = "ffmpeg"    # => path to the FFmpeg executable

COPY      = false       # => if set to true, just does a bitstream copy
                        # => if set to false, encoding options below are used

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
OUT_INDEX   = 5   # => CSV column for the edit out-point (FIXME: unused)
DIFF_INDEX  = 7   # => CSV column for the duration of edits


# Below options are only used when NOT copying:

CODEC     = "libx264"   # => encoder to be used (e.g. libx264, libxvid)
PROFILE   = "baseline"  # => x264 profile to be used (e.g. baseline)
EXT       = "mp4"       # => extension for the destination file (e.g. mp4)

BITRATE   = "500K"      # => target bitrate (e.g. 500K, 1M)
FRAMERATE = "25"        # => target framerate (in Hz)
SIZE      = "854x480"   # => target size (in pixels, WxH)

# ----------------------------------------------------------------------------
# DO NOT CHANGE ANYTHING BELOW THIS LINE
# ----------------------------------------------------------------------------

if RUBY_VERSION =~ /1\.8[\.\d]*/
  puts "Doesn't work with #{RUBY_VERSION}, needs at least 1.9.2"
  exit
end

require 'csv'

if ARGV.length != 3
  puts "Usage: video-extract.rb <csv> <input> <output>"
  puts "       <csv>    the file with the input data"
  puts "       <input>  an input folder containing the videos"
  puts "       <output> an output folder for the results"
  exit
end

input_file = ARGV[0]
in_dir = ARGV[1]
out_dir = ARGV[2]

if not File.file?(input_file)
  puts "Input CSV file not found or readable" 
  exit
end

if not File.directory?(in_dir)
  puts "Input folder not found or readable"
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
    video     = row[VIDEO_INDEX]
    input     = row[INPUT_FILE]
    output    = input.chomp(INPUT_FORMAT)
    inpoint   = row[IN_INDEX]
    outpoint  = row[OUT_INDEX]
    diff      = row[DIFF_INDEX]
    begin
      if COPY
        command = "#{FFMPEG} #{OVERWRITE} -ss #{inpoint} -i \"#{in_dir}/#{input}\" -c copy -t #{diff} \"#{out_dir}/#{prefix}-video_#{video}-#{output}.#{EXT}\""
      else
        command = "#{FFMPEG} #{OVERWRITE} -ss #{inpoint} -i \"#{in_dir}/#{input}\" -c:v #{CODEC} -r #{FRAMERATE} -profile:v #{PROFILE} -b:v #{BITRATE} -s:v #{SIZE} -t #{diff} -c:a copy  \"#{out_dir}/#{prefix}-video_#{video}-#{output}.#{EXT}\""
      end
      puts "--------------------------------------------------------------"
      puts "Command to execute: "
      puts command
      system(command)
    rescue
      puts "Error while executing the command. Skipping to next one."
    end
  end
rescue
  puts "Error while reading CSV file. Exiting."
end
