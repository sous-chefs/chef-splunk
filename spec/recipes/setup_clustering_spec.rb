require_relative '../spec_helper'

describe 'chef-splunk::setup_clustering' do
  let(:secrets) do
    {
      'splunk__default' => {
        'id' => 'splunk__default',
        'auth' => 'admin:notarealpassword',
        'secret' => 'notarealsecret'
      }
    }
  end

  let(:cluster_master_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'cm.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.normal['dev_mode'] = true
      node.normal['splunk']['is_server'] = true
      node.normal['splunk']['clustering']['enabled'] = true
      node.normal['splunk']['clustering']['mode'] = 'master'
    end
  end

  context 'default server settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.normal['splunk']['is_server'] = true
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'does nothing' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

  context 'invalid cluster mode settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.normal['dev_mode'] = true
        node.normal['splunk']['is_server'] = true
        node.normal['splunk']['clustering']['enabled'] = true
        node.normal['splunk']['clustering']['mode'] = 'foo'
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    # BUG: Chefspec does not suppress the error message despite raise_error
    # it 'raises an error' do
    #   expect(chef_run).to raise_error
    # end

    # it 'does not run edit cluster-config' do
    #   expect(chef_run).to_not run_execute('setup-indexer-cluster')
    # end
  end

  context 'indexer cluster master settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.normal['dev_mode'] = true
        node.normal['splunk']['is_server'] = true
        node.normal['splunk']['clustering']['enabled'] = true
        node.normal['splunk']['clustering']['mode'] = 'master'
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs edit cluster-config with correct parameters' do
      expect(chef_run).to run_execute('setup-indexer-cluster').with(
        'command' => "/opt/splunk/bin/splunk edit cluster-config -mode master\
 -replication_factor 3 -search_factor 2 -secret #{secrets['splunk__default']['secret']} -auth '#{secrets['splunk__default']['auth']}'"
      )
      expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_cluster_master').with_content('true\n')
    end
  end

  context 'indexer cluster master with custom settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.normal['dev_mode'] = true
        node.normal['splunk']['is_server'] = true
        node.normal['splunk']['clustering']['enabled'] = true
        node.normal['splunk']['clustering']['mode'] = 'master'
        node.normal['splunk']['clustering']['replication_factor'] = 5
        node.normal['splunk']['clustering']['search_factor'] = 3
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs edit cluster-config with correct parameters' do
      expect(chef_run).to run_execute('setup-indexer-cluster').with(
        'command' => "/opt/splunk/bin/splunk edit cluster-config -mode master\
 -replication_factor 5 -search_factor 3 -secret #{secrets['splunk__default']['secret']} -auth '#{secrets['splunk__default']['auth']}'"
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
        node.normal['dev_mode'] = true
        node.normal['splunk']['is_server'] = true
        node.normal['splunk']['clustering']['enabled'] = true
        node.normal['splunk']['clustering']['mode'] = 'searchhead'
        # Publish mock cluster master node to the server
        server.create_node(cluster_master_node)
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'runs edit cluster-config with correct parameters' do
      expect(chef_run).to run_execute('setup-indexer-cluster').with(
        'command' => "/opt/splunk/bin/splunk edit cluster-config -mode searchhead\
 -master_uri https://cm.cluster.example.com:8089 -replication_port 9887\
 -secret #{secrets['splunk__default']['secret']} -auth '#{secrets['splunk__default']['auth']}'"
      )
      expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_cluster_searchhead').with_content('true\n')
    end
  end
end
