require 'spec_helper'

describe 'chef-splunk::upgrade' do
  let(:url) { 'http://splunk.example.com/server/package437.deb' }

  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
      node.force_default['splunk']['upgrade_enabled'] = true
      node.force_default['splunk']['accept_license'] = true
      node.force_default['splunk']['server']['upgrade']['url'] = url
      node.force_default['splunk']['server']['upgrade']['version'] = '8.0.6'
    end
  end

  context 'is server' do
    it 'ran the splunk installer to upgrade' do
      chef_run.node.force_default['splunk']['is_server'] = true
      chef_run.node.force_default['splunk']['server']['upgrade']['url'] = url
      chef_run.converge(described_recipe)
      expect(chef_run).to upgrade_splunk_installer('splunk upgrade').with(url: url)
    end
  end

  context 'is not server' do
    it 'ran the splunk installer to upgrade forwarder' do
      chef_run.node.force_default['splunk']['is_server'] = false
      chef_run.node.force_default['splunk']['forwarder']['upgrade']['url'] = url
      chef_run.converge(described_recipe)
      expect(chef_run).to upgrade_splunk_installer('splunkforwarder upgrade').with(url: url)
    end
  end

  context 'upgrade from package manager' do
    it 'to specified version' do
      chef_run.node.force_default['splunk']['is_server'] = false
      chef_run.node.force_default['splunk']['forwarder']['upgrade']['url'] = ''
      chef_run.converge(described_recipe)
      expect(chef_run).to upgrade_splunk_installer('splunkforwarder upgrade').with(version: '8.0.6')
    end
  end
end
