require 'chefspec'
require 'chefspec/berkshelf'

FIXTURES_DIR = ::File.join('test', 'fixtures')
DATA_BAG_DIR = ::File.join(FIXTURES_DIR, 'data_bags')

RSpec.configure do |config|
  config.color = true               # Use color in STDOUT
  config.formatter = :documentation # Use the specified formatter
  config.log_level = :error         # Avoid deprecation notice SPAM

  config.platform = 'ubuntu'        # Avoid warnings in ChefSpec
  config.version = '16.04'          # Avoid warnings in ChefSpec

  config.alias_it_should_behave_like_to :it_performs, 'performs'
end

def create_data_bag_item(server, bag, item)
  db_path = ::File.join(DATA_BAG_DIR, bag, "#{item}.json")
  server.create_data_bag(bag, item => JSON.parse(::File.read(db_path)))
end
