require 'dm-core'
require 'dm-oracle-adapter'
require 'yaml'

puts __FILE__
config_file_path = File.expand_path(File.dirname(__FILE__)) + "/../config/database.yml"
puts "#{config_file_path}" 
DB_CONFIG = YAML::load(File.read(config_file_path))

DataMapper.setup(:UW_TEST,
 {:adapter => 'oracle', 
  :username => DB_CONFIG['UW_TEST']['username'], 
  :password => DB_CONFIG['UW_TEST']['password'],
  :host => DB_CONFIG['UW_TEST']['host'],
  :port => DB_CONFIG['UW_TEST']['port'],
  :path => DB_CONFIG['UW_TEST']['path']})

DataMapper.setup(:UW,
 {:adapter => 'oracle',
  :username => DB_CONFIG['UW_PROD']['username'],
  :password => DB_CONFIG['UW_PROD']['password'],
  :host => DB_CONFIG['UW_PROD']['host'],
  :port => DB_CONFIG['UW_PROD']['port'],
  :path => DB_CONFIG['UW_PROD']['path']})

