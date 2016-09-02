#!/usr/bin/env ruby

# Copyright (c) 2016 Leander Sabel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Load required libraries
require 'yaml'
require 'aws-sdk'

def load_config(filename)
	# Abort if no configuration file was provided
	abort "Configuration file not found. Exiting!" unless filename

	# Attempt to add '.yaml' if the file cannot be found
	filename.concat('.yaml') if !File.file?(filename) && !filename.end_with?('.yaml')

	# Abort if no configuration file is available
  abort "\'#{filename}\' could not be found." unless File.file?(filename)

  puts "Loading configuration from '#{filename}' ..."
	YAML.load_file(filename)
end

def find_amis_with_name(ec2, name)
  puts "Searching for AMI with name '#{name}' ... "
   ec2.describe_images({
    dry_run: false,
    owners: ["self"],
    filters: [
    {
      name: "name",
      values: [name],
      },
    ],
  }).images
end

def find_instances_with_name(ec2, name)
  puts "Searching for instance with name '#{name}' ..."
  reservation = ec2.describe_instances(
    filters:[{
      name: 'tag:Name',
      values: [name]
  }]).reservations[0]

  reservation.nil? ? Array.new : reservation.instances
end

def add_nametag(ec2, id, name)
  puts "Adding name '#{name}' to resource with id '#{id}' ..."
  ec2.create_tags({
    dry_run: false,
    resources: [id],
    tags: [
      {
        key: "Name",
        value: name,
      },],
    })
end
