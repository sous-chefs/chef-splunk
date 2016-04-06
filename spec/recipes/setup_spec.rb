require_relative '../spec_helper'

describe 'chef-splunk::setup' do
  context 'Mock all the include_recipe and configure input/output' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.set['splunk']['inputs_conf']['host'] = 'localhost'
      end.converge(described_recipe)
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

    it 'creates an inputs template in the local system directory if it has hosts' do
      expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/inputs.conf')
    end

    it 'notifies the splunk service to restart when rendering the inputs template' do
      resource = chef_run.template('/opt/splunkforwarder/etc/system/local/inputs.conf')
      expect(resource).to notify('service[splunk]').to(:restart)
    end
  end

  context 'Define splunk_servers' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        splunk_server = {}
        splunk_server['hostname'] = 'spelunker'
        splunk_server['ipaddress'] = '10.10.15.43'
        splunk_server['splunk'] = {}
        splunk_server['splunk']['receiver_port'] = '1648'
        node.set['splunk']['splunk_servers'] = [splunk_server]
      end.converge(described_recipe)
    end

    before(:each) do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    end

    it 'defines servers hash' do
      expect(chef_run.node['splunk']['output_groups']['default']['servers']).to eq ['ipaddress' => '10.10.15.43', 'port' => '1648']
    end
  end

  context 'Include all recipes' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new.converge(described_recipe)
    end

    it 'includes service and setup_auth recipes' do
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::service')
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::setup_auth')
      chef_run
    end
  end

  context 'Disable setup_auth' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.set['splunk']['setup_auth'] = false
        allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('chef-splunk::service').and_return(true)
      end.converge(described_recipe)
    end

    it 'includes service and setup_auth recipes' do
      expect(chef_run).to_not include_recipe('chef-splunk::setup_auth')
    end
  end
end
