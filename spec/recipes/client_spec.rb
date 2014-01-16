require_relative '../spec_helper'

describe 'chef-splunk::client' do
  let(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  before(:each) do
    Chef::Recipe.any_instance.stub(:include_recipe)
    splunk_server = Hash.new
    splunk_server['hostname'] = 'spelunker'
    splunk_server['ipaddress'] = '10.10.15.43'
    splunk_server['splunk'] = Hash.new
    splunk_server['splunk']['receiver_port'] = '1648'
    stub_search(:node, 'splunk_is_server:true AND chef_environment:_default').and_return([splunk_server])
  end

  it 'creates the local system directory' do
    expect(chef_run).to create_directory('/opt/splunkforwarder/etc/system/local').with(
      'recursive' => true,
      'owner' => 'splunk',
      'group' => 'splunk'
    )
  end

  it 'creates an outputs template in the local system directory' do
    expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/outputs.conf')
  end

  it 'notifies the splunk service to restart when rendering the outputs template' do
    resource = chef_run.template('/opt/splunkforwarder/etc/system/local/outputs.conf')
    expect(resource).to notify('service[splunk]').to(:restart)
  end
end
