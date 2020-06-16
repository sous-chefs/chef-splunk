require 'spec_helper'

describe 'chef-splunk::setup_shclustering' do
  let(:splunk_local_dir) { '/opt/splunk/etc/apps/0_autogen_shcluster_config/local' }
  let(:server_conf_file) { "#{splunk_local_dir}/server.conf" }

  let(:deployer_node) do
    stub_node(platform: 'ubuntu', version: '16.04') do |node|
      node.automatic['fqdn'] = 'deploy.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['is_server'] = true
      node.force_default['splunk']['shclustering']['enabled'] = true
      node.force_default['splunk']['accept_license'] = true
    end
  end

  context 'search head deployer' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['mode'] = 'deployer'
        create_data_bag_item(server, 'vault', 'splunk__default')
      end.converge(described_recipe)
    end
  end

  context 'search head cluster member settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['mode'] = 'member'
        node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['shcluster_members'] = \
          %w(https://shcluster-member01:8089 https://shcluster-member02:8089 https://shcluster-member03:8089)
        create_data_bag_item(server, 'vault', 'splunk__default')
      end.converge(described_recipe)
    end

    it_behaves_like 'a search head cluster member'
  end

  context 'search head captain' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['mode'] = 'captain'
        node.force_default['splunk']['shclustering']['shcluster_members'] = \
          %w(https://shcluster-member01:8089 https://shcluster-member02:8089 https://shcluster-member03:8089)
        create_data_bag_item(server, 'vault', 'splunk__default')
        allow_any_instance_of(Chef::Resource).to receive(:shcaptain_elected?).and_return(false)
        allow_any_instance_of(Chef::Recipe).to receive(:ok_to_bootstrap_captain?).and_return(true)
      end.converge(described_recipe)
    end

    let(:shcluster_servers_list) do
      'https://shcluster-member01:8089,https://shcluster-member02:8089,https://shcluster-member03:8089'
    end

    it 'executes bootstrap sh-captain command' do
      expect(chef_run).to run_execute('bootstrap-shcluster-captain')
    end
  end
end
