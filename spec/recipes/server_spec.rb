require 'spec_helper'

describe 'chef-splunk::server' do
  let(:chef_run_init) do
    ChefSpec::ServerRunner.new do |node, server|
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['is_server'] = true
      node.force_default['splunk']['accept_license'] = true
      # Populate mock vault data bag to the server
      create_data_bag_item(server, 'vault', 'splunk__default')
    end
  end

  let(:chef_run) do
    chef_run_init.converge(described_recipe)
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:current_mgmt_port).and_return('8089')
  end

  context 'default settings' do
    let(:chef_run) do
      chef_run_init.converge(described_recipe)
    end

    before(:each) do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:current_mgmt_port).and_return('8089')
    end

    it 'does not update splunkd management port' do
      expect(chef_run).to_not run_execute('update-splunk-mgmt-port')
    end

    it 'enables receiver port' do
      expect(chef_run).to run_execute('enable-splunk-receiver-port').with(
        command: "/opt/splunk/bin/splunk enable listen 9997 -auth 'admin:notarealpassword'",
        sensitive: true
      )
    end
  end

  context 'custom management port' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['mgmt_port'] = '9089'
        # Populate mock vault data bag to the server
        create_data_bag_item(server, 'vault', 'splunk__default')
      end.converge(described_recipe)
    end

    before(:each) do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:current_mgmt_port).and_return('8089')
    end

    it 'updates splunkd management port' do
      expect(chef_run).to run_execute('update-splunk-mgmt-port').with(
        command: "/opt/splunk/bin/splunk set splunkd-port 9089 -auth 'admin:notarealpassword'",
        sensitive: true
      )
    end

    it 'notifies the splunk service to restart when changing management port' do
      execution = chef_run.execute('update-splunk-mgmt-port')
      expect(execution).to notify('service[splunk]').to(:restart)
    end

    it 'enables receiver port' do
      expect(chef_run).to run_execute('enable-splunk-receiver-port').with(
        command: "/opt/splunk/bin/splunk enable listen 9997 -auth 'admin:notarealpassword'",
        sensitive: true
      )
    end
  end
end
