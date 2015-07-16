require_relative '../spec_helper'

describe 'chef-splunk::setup_clustering' do
  let(:secrets) do
    {
      'id' => 'splunk__default',
      'auth' => 'admin:notarealpassword',
      'secret' => 'notarealsecret'
    }
  end

  let(:cluster_master_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'cm.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.set['splunk']['is_server'] = true
      node.set['splunk']['clustering']['enable'] = true
      node.set['splunk']['clustering']['mode'] = 'master'
    end
  end

  before(:each) do
    # Force fallback to regular data bag in chef-vault's helper method chef_vault_item()
    allow(Chef::DataBag).to receive(:load).with('vault').and_return({})
    # Return above secrets data when requested by setup_clustering
    allow(Chef::DataBagItem).to receive(:load).with('vault', 'splunk__default').and_return(secrets)
  end

  context 'default server settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.set['splunk']['is_server'] = true
      end.converge(described_recipe)
    end

    it 'does nothing' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

  context 'indexer cluster master settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.set['splunk']['is_server'] = true
        node.set['splunk']['clustering']['enable'] = true
        node.set['splunk']['clustering']['mode'] = 'master'
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do # ~FC005
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs edit cluster-config with correct parameters' do
      expect(chef_run).to run_execute('setup-indexer-cluster').with(
        'command' => "/opt/splunk/bin/splunk edit cluster-config -mode master\
 -replication_factor 3 -search_factor 2 -secret #{secrets['secret']} -auth '#{secrets['auth']}'"
      )
      expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_cluster_master').with_content('true\n')
    end
  end

  context 'indexer cluster search head settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.set['splunk']['is_server'] = true
        node.set['splunk']['clustering']['enable'] = true
        node.set['splunk']['clustering']['mode'] = 'searchhead'
        # Publich mock cluster master node to the server for testing
        server.create_node(cluster_master_node)
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs edit cluster-config with correct parameters' do
      expect(chef_run).to run_execute('setup-indexer-cluster').with(
        'command' => "/opt/splunk/bin/splunk edit cluster-config -mode searchhead\
 -master_uri https://cm.cluster.example.com:8089 -replication_port 9887\
 -secret #{secrets['secret']} -auth '#{secrets['auth']}'"
      )
      expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_cluster_searchhead').with_content('true\n')
    end
  end
end
