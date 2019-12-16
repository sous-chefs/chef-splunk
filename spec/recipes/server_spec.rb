require 'spec_helper'

describe 'chef-splunk::server' do
  let(:chef_run_init) do
    ChefSpec::ServerRunner.new do |node|
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['accept_license'] = true
    end
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    allow_any_instance_of(Chef::Resource).to receive(:current_mgmt_port).and_return('8089')
    allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return('auth' => 'admin:notarealpassword')
  end

  context 'default settings' do
    let(:chef_run) do
      chef_run_init.converge(described_recipe)
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
      chef_run_init.node.force_default['dev_mode'] = true
      chef_run_init.node.force_default['splunk']['accept_license'] = true
      chef_run_init.node.force_default['splunk']['mgmt_port'] = '9089'
      chef_run_init.converge(described_recipe)
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
