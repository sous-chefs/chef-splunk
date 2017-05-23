require_relative '../spec_helper'

describe 'chef-splunk::server' do
  let(:secrets) do
    {
      'splunk__default' => {
        'id' => 'splunk__default',
        'auth' => 'admin:notarealpassword',
        'secret' => 'notarealsecret',
      },
    }
  end

  let(:chef_run_init) do
    ChefSpec::ServerRunner.new do |node, server|
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
      # Populate mock vault data bag to the server
      server.create_data_bag('vault', secrets)
    end
  end

  let(:chef_run) do
    chef_run_init.converge(described_recipe)
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    stub_command("/opt/splunk/bin/splunk enable listen 9997 -auth '#{secrets['splunk__default']['auth']}'").and_return(true)
    # Stub TCP Socket to immediately fail connection to 9997 and raise error without waiting for entire default timeout
    allow(TCPSocket).to receive(:new).with(anything, '9997') { raise Errno::ETIMEDOUT }
  end

  context 'default settings' do
    before(:each) do
      stub_command("/opt/splunk/bin/splunk show splunkd-port -auth '#{secrets['splunk__default']['auth']}' | grep ': 8089'").and_return('Splunkd port: 8089')
    end

    it 'does not update splunkd management port' do
      expect(chef_run).to_not run_execute('update-splunk-mgmt-port')
    end

    it 'enables receiver port' do
      expect(chef_run).to run_execute('enable-splunk-receiver-port').with(
        'command' => "/opt/splunk/bin/splunk enable listen 9997 -auth '#{secrets['splunk__default']['auth']}'"
      )
    end
  end

  context 'custom management port' do
    before(:each) do
      stub_command("/opt/splunk/bin/splunk show splunkd-port -auth '#{secrets['splunk__default']['auth']}' | grep ': 9089'").and_return(false)
      chef_run_init.node.set['splunk']['mgmt_port'] = '9089'
    end

    it 'updates splunkd management port' do
      expect(chef_run).to run_execute('update-splunk-mgmt-port').with(
        'command' => "/opt/splunk/bin/splunk set splunkd-port 9089 -auth '#{secrets['splunk__default']['auth']}'"
      )
    end

    it 'notifies the splunk service to restart when changing management port' do
      execution = chef_run.execute('update-splunk-mgmt-port')
      expect(execution).to notify('service[splunk]').to(:restart)
    end

    it 'enables receiver port' do
      expect(chef_run).to run_execute('enable-splunk-receiver-port').with(
        'command' => "/opt/splunk/bin/splunk enable listen 9997 -auth '#{secrets['splunk__default']['auth']}'"
      )
    end
  end
end
