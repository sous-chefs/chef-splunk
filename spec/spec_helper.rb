require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.color = true               # Use color in STDOUT
  config.formatter = :documentation # Use the specified formatter
  config.log_level = :error         # Avoid deprecation notice SPAM

  config.platform = 'ubuntu'        # Avoid warnings in ChefSpec
  config.version = '16.04'          # Avoid warnings in ChefSpec

  config.alias_it_should_behave_like_to :it_performs, 'performs'
end
