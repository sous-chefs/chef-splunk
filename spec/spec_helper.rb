require 'chefspec'
require 'chefspec/berkshelf'
require 'shared_examples'
require_relative 'shared_contexts'

TEST_DIR = ::File.join('test', 'integration')
DATA_BAG_DIR = ::File.join(TEST_DIR, 'data_bags')

def create_data_bag_item(server, bag, item)
  db_path = ::File.join(DATA_BAG_DIR, bag, "#{item}.json")
  server.create_data_bag(bag, item => JSON.parse(::File.read(db_path)))
end

RSpec.configure do |config|
  config.color = true               # Use color in STDOUT
  config.formatter = :documentation # Use the specified formatter
  config.log_level = :error         # Avoid deprecation notice SPAM
  config.platform = 'ubuntu'        # Avoid warnings in ChefSpec
  config.version = '18.04'          # Avoid warnings in ChefSpec
  config.example_status_persistence_file_path = 'spec/reports/examples.txt'
  config.alias_it_should_behave_like_to :it_performs, 'performs'
  config.include_context 'command stubs'
end
