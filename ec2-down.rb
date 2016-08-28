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

# Find instances with image id
instances = find_instances_with_name(ec2, config['ami_name'])

# Handling of unexpected system state
abort "No instance with name '#{config['ami_name']}' found. Exiting!" if instances.length == 0

# Check if old images exist for this machine and delete them
find_amis_with_name(ec2, config['ami_name']).each do |image|
  puts "Found matching image with image id '#{image.image_id}' ... "

  puts "Deregistering that AMI ..."
  ec2.deregister_image({image_id: image.image_id,})

  puts "Deleting AMI's backing Snapshot ..."
  ec2.delete_snapshot(snapshot_id: image.block_device_mappings[0].ebs.snapshot_id)
end

puts "Starting AMI creation ..."
image = ec2.create_image({instance_id: instances[0].instance_id, name: config['ami_name']})

puts "Waiting for AMI to be created ..."
if ec2.wait_until(:image_available, image_ids:[image.image_id]) then
  puts "Image with image id #{image.image_id} has been created"
else
  abort "AMI was not created successfully. Exiting without terminating the instance"
end

puts "Terminating all instances of type #{config['ami_name']}' ..."
instances.each do |instance|
  puts "Terminating '#{instance.instance_id}'"
  ec2.terminate_instances({instance_ids: [instance.instance_id]})
end

puts "All done!"
