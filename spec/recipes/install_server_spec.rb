require_relative '../spec_helper'

describe 'chef-splunk::install_server' do
  context 'debian family' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        step_into: ['splunk_installer'],
        platform: 'ubuntu',
        version: '12.04'
      ) do |node|
        node.normal['splunk']['server']['url'] = 'http://splunk.example.com/server/package.deb'
      end.converge(described_recipe)
    end

    it 'caches the package with remote_file' do
      expect(chef_run).to create_remote_file_if_missing("#{Chef::Config[:file_cache_path]}/package.deb")
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_dpkg_package('splunk').with(
        'source' => "#{Chef::Config[:file_cache_path]}/package.deb"
      )
    end
  end

  context 'redhat family' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        step_into: ['splunk_installer'],
        platform: 'centos',
        version: '6.4'
      ) do |node|
        node.normal['splunk']['server']['url'] = 'http://splunk.example.com/server/package.rpm'
      end.converge(described_recipe)
    end

    it 'caches the package with remote_file' do
      expect(chef_run).to create_remote_file_if_missing("#{Chef::Config[:file_cache_path]}/package.rpm")
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_rpm_package('splunk').with(
        'source' => "#{Chef::Config[:file_cache_path]}/package.rpm"
      )
    end
  end

  context 'omnios family' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        step_into: ['splunk_installer'],
        platform: 'omnios',
        version: '151018'
      ) do |node|
        node.normal['splunk']['server']['url'] = 'http://splunk.example.com/server/package.pkg.Z'
      end.converge(described_recipe)
    end

    before(:each) do
      stub_command('grep -q /home/splunk /etc/passwd').and_return(false)
    end

    it 'caches the package with remote_file' do # ~FC005
      expect(chef_run).to create_remote_file_if_missing("#{Chef::Config[:file_cache_path]}/package.pkg.Z")
    end

    it 'uncompresses the package file' do
      expect(chef_run).to run_execute("uncompress #{Chef::Config[:file_cache_path]}/package.pkg.Z")
    end

    it 'writes out the nocheck file' do
      expect(chef_run).to create_cookbook_file("#{Chef::Config[:file_cache_path]}/splunk-nocheck")
    end

    it 'writes out the response file' do
      expect(chef_run).to create_file("#{Chef::Config[:file_cache_path]}/splunk-response").with(
        'content' => 'BASEDIR=/opt'
      )
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_solaris_package('splunk').with(
        'source' => "#{Chef::Config[:file_cache_path]}/package.pkg",
        'options' => "-a #{Chef::Config[:file_cache_path]}/splunk-nocheck -r #{Chef::Config[:file_cache_path]}/splunk-response"
      )
    end
  end
end
