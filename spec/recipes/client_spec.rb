require_relative '../spec_helper'

describe 'chef-splunk::client' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new.converge(described_recipe)
  end

  it 'includes user, install_forwarder and setup recipes (setup is performing client config)' do
    expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::user')
    expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::install_forwarder')
    expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::setup')
    chef_run
  end
end
