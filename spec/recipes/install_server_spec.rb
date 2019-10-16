require 'spec_helper'

describe 'chef-splunk::install_server' do
  platforms = {
    debian: {
      runner: {
        platform: 'ubuntu',
        version: '16.04',
      },
      url: 'http://splunk.example.com/server/package.deb',
    },
    redhat: {
      runner: {
        platform: 'centos',
        version: '7',
      },
      url: 'http://splunk.example.com/server/package.rpm',
    },
  }

  platforms.each do |platform, platform_under_test|
    context "#{platform} family" do
      let(:url) { platform_under_test[:url] }

      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform_under_test[:runner])
      end

      it 'ran the splunk installer' do
        chef_run.node.force_default['splunk']['server']['url'] = url
        chef_run.converge(described_recipe)
        expect(chef_run).to run_splunk_installer('splunk').with(url: url)
      end

      context 'install from package manager' do
        it 'should install splunk forwarder from local repo' do
          chef_run.node.force_default['splunk']['server']['url'] = ''
          chef_run.node.force_default['splunk']['server']['version'] = '6.6.0'
          chef_run.converge(described_recipe)
          expect(chef_run).to run_splunk_installer('splunk').with(version: '6.6.0')
        end
      end
    end
  end
end
