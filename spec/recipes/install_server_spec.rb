require_relative '../spec_helper'

describe 'chef-splunk::install_server' do
  context 'debian family' do
    let(:url) { 'http://splunk.example.com/server/package.deb' }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'ubuntu',
        version: '16.04'
      ) do |node|
        node.force_default['splunk']['server']['url'] = url
      end.converge(described_recipe)
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunk').with(url: url)
    end
  end

  context 'redhat family' do
    let(:url) { 'http://splunk.example.com/server/package.rpm' }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'centos',
        version: '7'
      ) do |node|
        node.force_default['splunk']['server']['url'] = url
      end.converge(described_recipe)
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunk').with(url: url)
    end
  end
end
