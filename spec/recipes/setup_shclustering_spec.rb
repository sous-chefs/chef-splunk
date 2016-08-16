require_relative '../spec_helper'

describe 'chef-splunk::setup_shclustering' do
	let(:secrets) do
    {
      'splunk__default' => {
        'id' => 'splunk__default',
        'auth' => 'admin:notarealpassword',
        'secret' => 'notarealsecret',
        'shcluster_secret' => 'secretsquirrel'
      }
    }
  end

  let(:deployer_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'deploy.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
      node.set['splunk']['shclustering']['enabled'] = true
    end
  end

  let(:sh1_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'sh1.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.11'
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
      node.set['splunk']['shclustering']['enabled'] = true
    end
  end

  let(:sh2_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'sh2.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.12'
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
      node.set['splunk']['shclustering']['enabled'] = true
    end
  end

  let(:sh3_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'sh3.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.13'
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
      node.set['splunk']['shclustering']['enabled'] = true
    end
  end

  context 'default server settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.set['splunk']['is_server'] = true
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'does nothing' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

	context 'with valid shcluster settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.set['dev_mode'] = true
        node.set['splunk']['is_server'] = true
        node.set['splunk']['shclustering']['enabled'] = true
        node.set['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node.fqdn}:8089",
        node.set['splunk']['shclustering']['shcluster_members'] = [ 
        	"https://#{sh1_node.fqdn}:8089",
        	"https://#{sh2_node.fqdn}:8089",
        	"https://#{sh3_node.fqdn}:8089"
        ]
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    let(:shcluster_servers_list) do
    	chef_run.node['splunk']['shclustering']['shcluster_members'].join(',')
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs init-shcluster-config with correct parameters' do
    	expect(chef_run).to run_execute('init-shcluster-config').with(
        'command' => "/opt/splunk/bin/splunk init shcluster-config -mgmt_uri #{chef_run.node['splunk']['shclustering']['mgmt_uri']}\
 -replication_factor #{chef_run.node['splunk']['shclustering']['replication_factor']}\
 -replication_port #{chef_run.node['splunk']['shclustering']['replication_port']}\
 -conf_deploy_fetch_url #{chef_run.node['splunk']['shclustering']['deployer_url']}\
 -secret #{secrets['splunk__default']['shcluster_secret']}\
 -auth '#{secrets['splunk__default']['auth']}'"
      )
      expect(chef_run.execute('init-shcluster-config')).to notify('service[splunk]').to(:restart)
    end

    it 'runs bootstrap shcluster-captain with correct parameters' do
      expect(chef_run).to run_execute('bootstrap-shcluster').with(
        'command' => "/opt/splunk/bin/splunk bootstrap shcluster-captain -servers_list #{shcluster_servers_list}\
 -auth '#{secrets['splunk__default']['auth']}'"
      )
      expect(chef_run.execute('bootstrap-shcluster')).to notify('service[splunk]').to(:restart)
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_shcluster').with_content('true\n')
    end
  end
end