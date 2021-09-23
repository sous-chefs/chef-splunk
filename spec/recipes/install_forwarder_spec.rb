require 'spec_helper'

describe 'chef-splunk::install_forwarder' do
  platforms = {
    debian: {
      runner: {
        platform: 'ubuntu',
        version: '20.04',
      },
      url: 'http://splunk.example.com/forwarder/package.deb',
    },
    redhat: {
      runner: {
        platform: 'centos',
        version: '8',
      },
      url: 'http://splunk.example.com/forwarder/package.rpm',
    },
  }

  platforms.each do |platform, platform_under_test|
    context "#{platform} family" do
      let(:url) { platform_under_test[:url] }

      context 'url value exists' do
        cached(:chef_run) do
          ChefSpec::ServerRunner.new(platform_under_test[:runner]) do |node, server|
            create_data_bag_item(server, 'vault', 'splunk__default')
            node.force_default['splunk']['forwarder']['version'] = '8.0.1'
            node.force_default['splunk']['accept_license'] = true
            node.force_default['chef-vault']['databag_fallback'] = true
            node.force_default['splunk']['forwarder']['url'] = url
          end.converge(described_recipe)
        end

        it 'install splunk forwarder from package downloaded from URL' do
          expect(chef_run).to run_splunk_installer('splunkforwarder')
            .with(url: url, package_name: 'splunkforwarder')
        end
      end

      context 'url attribute is empty' do
        cached(:chef_run) do
          ChefSpec::ServerRunner.new(platform_under_test[:runner]) do |node, server|
            create_data_bag_item(server, 'vault', 'splunk__default')
            node.force_default['splunk']['forwarder']['version'] = '8.0.1'
            node.force_default['splunk']['accept_license'] = true
            node.force_default['chef-vault']['databag_fallback'] = true
            node.force_default['splunk']['forwarder']['url'] = ''
          end.converge(described_recipe)
        end

        it 'should install splunk forwarder from local repo' do
          expect(chef_run).to run_splunk_installer('splunkforwarder')
            .with(url: '', package_name: 'splunkforwarder')
        end
      end
    end
  end
end
