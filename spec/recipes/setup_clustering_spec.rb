require_relative '../spec_helper'

shared_examples 'a successful run' do |params|
  it 'includes chef-vault' do
    expect(chef_run).to include_recipe('chef-vault::default')
  end

  it 'runs edit cluster-config with correct parameters' do
    expect(chef_run).to run_execute('setup-indexer-cluster').with(
      'command' => '/opt/splunk/bin/splunk edit cluster-config ' +
                    params + " -secret #{secrets['splunk__default']['secret']} -auth '#{secrets['splunk__default']['auth']}'"
    )
    expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
  end

  it 'writes a file marker to ensure convergence' do
    expect(chef_run).to render_file('/opt/splunk/etc/.setup_clustering').with_content('true\n')
  end
end

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

  let(:chef_run_init) do
    ChefSpec::ServerRunner.new do |node, server|
      node.normal['dev_mode'] = true
      node.normal['splunk']['is_server'] = true
      # Populate mock vault data bag to the server
      server.create_data_bag('vault', secrets)
    end
  end

  let(:chef_run) do
    chef_run_init.converge(described_recipe)
  end

  context 'default server settings' do
    it 'does nothing' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

  context 'invalid cluster mode settings' do
    before(:each) do
      chef_run_init.node.normal['splunk']['clustering']['enabled'] = true
      chef_run_init.node.normal['splunk']['clustering']['mode'] = 'foo'
    end

    it 'raises an error' do
      expect { chef_run }.to raise_error(RuntimeError)
    end
  end

  context 'cluster master mode' do
    before(:each) do
      chef_run_init.node.normal['splunk']['clustering']['enabled'] = true
      chef_run_init.node.normal['splunk']['clustering']['mode'] = 'master'
    end

    context 'default settings (single-site)' do
      it_performs 'a successful run', '-mode master -replication_factor 3 -search_factor 2'
    end

    context 'multisite clustering with default settings' do
      before(:each) do
        chef_run_init.node.normal['splunk']['clustering']['num_sites'] = 2
      end

      it_performs 'a successful run', "-mode master -multisite true -available_sites site1,site2 -site site1\
 -site_replication_factor origin:2,total:3 -site_search_factor origin:1,total:2"
    end

    context 'single-site clustering with custom settings' do
      before(:each) do
        chef_run_init.node.normal['splunk']['clustering']['replication_factor'] = 5
        chef_run_init.node.normal['splunk']['clustering']['search_factor'] = 3
      end

      it_performs 'a successful run', '-mode master -replication_factor 5 -search_factor 3'
    end

    context 'multisite clustering with custom settings' do
      before(:each) do
        chef_run_init.node.normal['splunk']['clustering']['num_sites'] = 3
        chef_run_init.node.normal['splunk']['clustering']['site'] = 'site2'
        chef_run_init.node.normal['splunk']['clustering']['site_replication_factor'] = 'origin:2,site1:1,site2:1,total:4'
        chef_run_init.node.normal['splunk']['clustering']['site_search_factor'] = 'origin:1,site1:1,site2:1,total:3'
      end

      it_performs 'a successful run', "-mode master -multisite true -available_sites site1,site2,site3 -site site2\
 -site_replication_factor origin:2,site1:1,site2:1,total:4 -site_search_factor origin:1,site1:1,site2:1,total:3"
    end
  end

  context 'cluster search head mode' do
    before(:each) do
      chef_run_init.node.normal['splunk']['clustering']['enabled'] = true
      chef_run_init.node.normal['splunk']['clustering']['mode'] = 'searchhead'
      # Publish mock cluster master node to the server
      cluster_master_node = stub_node(platform: 'ubuntu', version: '12.04') do |node|
        node.automatic['fqdn'] = 'cm.cluster.example.com'
        node.automatic['ipaddress'] = '192.168.0.10'
        node.normal['dev_mode'] = true
        node.normal['splunk']['is_server'] = true
        node.normal['splunk']['mgmt_port'] = '8089'
        node.normal['splunk']['clustering']['enabled'] = true
        node.normal['splunk']['clustering']['mode'] = 'master'
      end
      chef_run_init.create_node(cluster_master_node)
    end

    context 'default settings (single-site)' do
      it_performs 'a successful run', '-mode searchhead -master_uri https://192.168.0.10:8089 -replication_port 9887'
    end

    context 'multisite clustering with default settings' do
      before(:each) do
        chef_run_init.node.normal['splunk']['clustering']['num_sites'] = 2
        chef_run_init.node.normal['splunk']['clustering']['site'] = 'site2'
      end

      it_performs 'a successful run', '-mode searchhead -site site2 -master_uri https://192.168.0.10:8089 -replication_port 9887'
    end
  end
end
