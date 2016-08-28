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

require_relative 'common'

# Creating EC2 client
ec2 = Aws::EC2::Client.new

# Load configuration file
config = load_config('default.yaml')

# Search for running instances and abort if an instance of this type is already running
find_instances_with_name(ec2, config['ami_name']).each do | instance |
  abort "Found instance with name '#{config['ami_name']}' in state '#{instance.state.name}'. Exiting." if instance.state.code <= 16
end

# Search for image and abort if no image can be found
images = find_amis_with_name(ec2, config['ami_name'])
abort "No image with name #{config['ami_name']} found." if images.length == 0
warn "More than one image of type #{config['ami_name']} found." if images.length > 1

# Start EC2 instance
puts "Starting EC2 instance with AMI #{images[0].image_id} ..."
instances = ec2.run_instances({
  image_id: images[0].image_id,
  min_count: 1,
  max_count: 1,
  instance_type: config['instance_type'],
  security_group_ids: [config['security_group_ids']],
}).instances

abort "Failed to launch instance" unless instances.length == 1

puts "Launching instance #{instances[0].instance_id} in #{instances[0].placement.availability_zone} ..."

# Set the instance name for later retrieval of the instance
add_nametag(ec2, instances[0].instance_id, config['ami_name'])

# Get public IP address
instance_ip = ec2.describe_instances({
    instance_ids: [instances[0].instance_id],
  }).reservations[0].instances[0].public_ip_address

puts "Instance starting with IP address #{instance_ip}"
puts "Waiting for instance to become available ..."

# Wait for instance to become available
ec2.wait_until(:instance_status_ok, instance_ids:[instances[0].instance_id])

puts "All done!"
