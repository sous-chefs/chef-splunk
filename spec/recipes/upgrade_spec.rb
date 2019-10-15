require 'spec_helper'

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

    it 'ran the splunk installer to upgrade' do
      expect(chef_run).to upgrade_splunk_installer('splunk upgrade').with(url: url)
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

    it 'ran the splunk installer to upgrade forwarder' do
      expect(chef_run).to upgrade_splunk_installer('splunkforwarder upgrade').with(url: url)
    end
  end
end
