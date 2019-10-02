require_relative '../spec_helper'

describe 'chef-splunk::upgrade' do
  context 'is server' do
    let(:url) { 'http://splunk.example.com/server/package437.deb' }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
        node.force_default['splunk']['upgrade_enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['upgrade']['server_url'] = url
        node.force_default['splunk']['is_server'] = true
      end.converge(described_recipe)
    end

    it 'stops splunk with a special service resource' do # ~FC005
      expect(chef_run).to stop_service('splunk_stop').with(
        'service_name' => 'splunk'
      )
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunk').with(url: url)
    end

    it 'runs an unattended upgrade (starts splunk)' do
      expect(chef_run).to run_execute('splunk-unattended-upgrade').with(
        'command' => '/opt/splunk/bin/splunk start --accept-license --answer-yes'
      )
    end
  end

  context 'is not server' do
    let(:url) { 'http://splunk.example.com/splunkforwarder/package437.deb' }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
        node.force_default['splunk']['upgrade_enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['upgrade']['forwarder_url'] = url
        node.force_default['splunk']['is_server'] = false
      end.converge(described_recipe)
    end

    it 'stops splunk with a special service resource' do # ~FC005
      expect(chef_run).to stop_service('splunk_stop').with(
        'service_name' => 'splunk'
      )
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunkforwarder').with(url: url)
    end

    it 'runs an unattended upgrade (starts splunk)' do
      expect(chef_run).to run_execute('splunk-unattended-upgrade').with(
        'command' => '/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes'
      )
    end
  end
end
