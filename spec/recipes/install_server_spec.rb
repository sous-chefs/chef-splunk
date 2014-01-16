require_relative '../spec_helper'

describe 'chef-splunk::install_server' do
  context 'debian family' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        :step_into => ['splunk_installer'],
        :platform => 'ubuntu',
        :version => '12.04'
      ) do |node|
        node.set['splunk']['server']['url'] = 'http://splunk.example.com/server/package.deb'
      end.converge(described_recipe)
    end

    it 'caches the package with remote_file' do
      expect(chef_run).to create_remote_file_if_missing('/var/chef/cache/package.deb')
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_package('splunk').with(
        'source' => '/var/chef/cache/package.deb'
      )
    end
  end

  context 'redhat family' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        :step_into => ['splunk_installer'],
        :platform => 'centos',
        :version => '6.4'
      ) do |node|
        node.set['splunk']['server']['url'] = 'http://splunk.example.com/server/package.rpm'
      end.converge(described_recipe)
    end

    it 'caches the package with remote_file' do
      expect(chef_run).to create_remote_file_if_missing('/var/chef/cache/package.rpm')
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_package('splunk').with(
        'source' => '/var/chef/cache/package.rpm'
      )
    end
  end

  context 'omnios family' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        :step_into => ['splunk_installer'],
        :platform => 'omnios',
        :version => '151002'
      ) do |node|
        node.set['splunk']['server']['url'] = 'http://splunk.example.com/server/package.pkg.Z'
      end.converge(described_recipe)
    end

    it 'caches the package with remote_file' do
      expect(chef_run).to create_remote_file_if_missing('/var/chef/cache/package.pkg.Z')
    end

    it 'uncompresses the package file' do
      expect(chef_run).to run_execute('uncompress /var/chef/cache/package.pkg.Z')
    end

    it 'writes out the nocheck file' do
      expect(chef_run).to create_cookbook_file('/var/chef/cache/splunk-nocheck')
    end

    it 'writes out the response file' do
      expect(chef_run).to create_file('/var/chef/cache/splunk-response').with(
        'content' => 'BASEDIR=/opt'
      )
    end

    it 'installs the package with the downloaded file' do
      expect(chef_run).to install_package('splunk').with(
        'source' => '/var/chef/cache/package.pkg',
        'options' => '-a /var/chef/cache/splunk-nocheck -r /var/chef/cache/splunk-response'
      )
    end
  end
end
