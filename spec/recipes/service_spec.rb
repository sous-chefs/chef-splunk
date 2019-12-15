require 'spec_helper'

describe 'chef-splunk::service' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new do |node|
      node.force_default['splunk']['accept_license'] = true
    end.converge(described_recipe)
  end

  it 'starts the splunk service' do
    expect(chef_run).to start_service('splunk')
  end
end
