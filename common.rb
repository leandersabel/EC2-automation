# Load required libraries
require 'yaml'

def load_config(filename)

	# Abort if no configuration file was proviced
	abort("No configuration file specified. Exiting...") unless filename


	# Attempt to add '.yaml' if the file cannot be found 
	filename.concat('.yaml') if !File.file?(filename) && !filename.end_with?('.yaml')

	abort("\'#{filename}\' could not be found.") unless File.file?(filename) 


	config = YAML.load_file(filename)

end