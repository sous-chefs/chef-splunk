require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.log_level = :fatal

  config.alias_it_should_behave_like_to :it_performs, 'performs'
end
