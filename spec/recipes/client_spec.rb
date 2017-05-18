require_relative '../spec_helper'

describe 'chef-splunk::client' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new.converge(described_recipe)
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    splunk_server = {}
    splunk_server['hostname'] = 'spelunker'
    splunk_server['ipaddress'] = '10.10.15.43'
    splunk_server['splunk'] = {}
    splunk_server['splunk']['receiver_port'] = '1648'
    stub_search(:node, 'splunk_is_server:true AND chef_environment:_default').and_return([splunk_server])
  end

  it 'creates the local system directory' do # ~FC005
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

  context 'inputs config has hosts' do
    before(:each) do
      chef_run.node.normal['splunk']['inputs_conf']['host'] = 'localhost'
      chef_run.converge(described_recipe)
    end

    it 'creates an inputs template in the local system directory if it has hosts' do
      expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/inputs.conf')
    end

    it 'notifies the splunk service to restart when rendering the inputs template' do
      resource = chef_run.template('/opt/splunkforwarder/etc/system/local/inputs.conf')
      expect(resource).to notify('service[splunk]').to(:restart)
    end
  end
end
