require_relative '../spec_helper'

describe 'chef-splunk::install_forwarder' do
  context 'debian family' do
    let(:url) { 'http://splunk.example.com/forwarder/package.deb' }

    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'ubuntu',
        version: '16.04'
      ) do |node|
        node.force_default['splunk']['forwarder']['url'] = url
      end.converge(described_recipe)
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunkforwarder').with(url: url)
    end
  end

  context 'redhat family' do
    let(:url) { 'http://splunk.example.com/forwarder/package.rpm' }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'centos',
        version: '7'
      ) do |node|
        node.force_default['splunk']['forwarder']['url'] = url
      end.converge(described_recipe)
    end

    it 'ran the splunk installer' do
      expect(chef_run).to run_splunk_installer('splunkforwarder').with(url: url)
    end
  end
end
