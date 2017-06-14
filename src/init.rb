require 'yaml'

DEV = (ENV['RACK_ENV']=='development')
Indico.api_key = YAML.load_file('auth.yml')["indico"]
