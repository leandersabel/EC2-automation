#!/usr/bin/env ruby

require_relative 'common'

load_config(nil)

# puts config['instance']['ami-name']



ARGV.each do|a|
  puts "Argument: #{a}"
end