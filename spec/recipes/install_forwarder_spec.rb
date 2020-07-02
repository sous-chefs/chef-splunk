require 'spec_helper'

describe 'chef-splunk::install_forwarder' do
  platforms = {
    debian: {
      runner: {
        platform: 'ubuntu',
        version: '16.04',
      },
      url: 'http://splunk.example.com/forwarder/package.deb',
    },
    redhat: {
      runner: {
        platform: 'centos',
        version: '7',
      },
      url: 'http://splunk.example.com/forwarder/package.rpm',
    },
  }

  platforms.each do |platform, platform_under_test|
    context "#{platform} family" do
      let(:url) { platform_under_test[:url] }

      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform_under_test[:runner]) do |node|
          node.force_default['splunk']['forwarder']['version'] = '8.0.1'
          node.force_default['splunk']['accept_license'] = true
        end
      end

      context 'url value exists' do
        it 'install splunk forwarder from package downloaded from URL' do
          chef_run.node.force_default['splunk']['forwarder']['url'] = url
          chef_run.converge(described_recipe)
          expect(chef_run).to run_splunk_installer('splunkforwarder')
            .with(url: url, version: '8.0.1', package_name: 'splunkforwarder')
        end
      end

      context 'url attribute is empty' do
        it 'should install splunk forwarder from local repo' do
          chef_run.node.force_default['splunk']['forwarder']['url'] = ''
          chef_run.converge(described_recipe)
          expect(chef_run).to run_splunk_installer('splunkforwarder')
            .with(url: '', version: '8.0.1', package_name: 'splunkforwarder')
        end
      end
    end
  end
end
