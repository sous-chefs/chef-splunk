require 'spec_helper'

shared_examples 'a successful run' do |params|
  it 'runs edit cluster-config with correct parameters' do
    cmd = "/opt/splunk/bin/splunk edit cluster-config #{params}" \
          " -secret notarealsecret -auth 'admin:notarealpassword'"
    expect(chef_run).to run_execute('setup-indexer-cluster').with(command: cmd, sensitive: true)
    expect(chef_run.execute('setup-indexer-cluster')).to notify('service[splunk]').to(:restart)
  end

  it 'writes a file marker to ensure convergence' do
    expect(chef_run).to create_file('/opt/splunk/etc/.setup_clustering')
  end
end

describe 'chef-splunk::setup_clustering' do
  before do
    allow_any_instance_of(::File).to receive(:exist?).and_call_original
    allow_any_instance_of(::File).to receive(:exist?).with('/opt/splunk/etc/.setup_clustering').and_return(false)
  end

  context 'default server settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['accept_license'] = true
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
      end.converge(described_recipe)
    end

    it 'does nothing' do
      expect(chef_run.resource_collection).to be_empty
    end
  end

  context 'clustering is enabled' do
    let(:chef_run_init) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['clustering']['enabled'] = true
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
      end
    end

    context 'invalid cluster mode settings' do
      let(:chef_run) do
        chef_run_init.node.force_default['splunk']['clustering']['mode'] = 'foo'
        chef_run_init
      end

      it 'raises an error' do
        expect { chef_run.converge(described_recipe) }.to raise_error(RuntimeError, 'Failed to setup clustering: invalid clustering mode')
      end
    end

    context 'cluster master mode' do
      let(:chef_run) do
        chef_run_init.node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        chef_run_init.node.run_state['splunk_secret'] = 'notarealsecret'
        chef_run_init.node.force_default['splunk']['clustering']['mode'] = 'master'
        chef_run_init
      end

      context 'default settings (single-site)' do
        before do
          chef_run.converge(described_recipe)
        end
        it_performs 'a successful run', '-mode master -replication_factor 3 -search_factor 2'
      end

      context 'multisite clustering with default settings' do
        let(:chef_run) do
          chef_run_init.node.force_default['splunk']['clustering']['num_sites'] = 2
          chef_run_init.node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
          chef_run_init.node.run_state['splunk_secret'] = 'notarealsecret'
          chef_run_init
        end

        before do
          chef_run.converge(described_recipe)
        end

        it_performs 'a successful run', '-mode master -multisite true -available_sites site1,site2 -site site1' \
                    ' -site_replication_factor origin:2,total:3 -site_search_factor origin:1,total:2'
      end

      context 'single-site clustering with custom settings' do
        let(:chef_run) do
          chef_run_init.node.force_default['splunk']['clustering']['replication_factor'] = 5
          chef_run_init.node.force_default['splunk']['clustering']['search_factor'] = 3
          chef_run_init.node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
          chef_run_init.node.run_state['splunk_secret'] = 'notarealsecret'
          chef_run_init
        end

        before do
          chef_run.converge(described_recipe)
        end

        it_performs 'a successful run', '-mode master -replication_factor 5 -search_factor 3'
      end

      context 'multisite clustering with custom settings' do
        let(:chef_run) do
          chef_run_init.node.force_default['splunk']['clustering']['num_sites'] = 3
          chef_run_init.node.force_default['splunk']['clustering']['site'] = 'site2'
          chef_run_init.node.force_default['splunk']['clustering']['site_replication_factor'] = 'origin:2,site1:1,site2:1,total:4'
          chef_run_init.node.force_default['splunk']['clustering']['site_search_factor'] = 'origin:1,site1:1,site2:1,total:3'
          chef_run_init
        end

        before do
          chef_run.converge(described_recipe)
        end

        it_performs 'a successful run', '-mode master -multisite true -available_sites site1,site2,site3 -site site2' \
                    ' -site_replication_factor origin:2,site1:1,site2:1,total:4 -site_search_factor origin:1,site1:1,site2:1,total:3'
      end
    end

    context 'cluster search head mode' do
      # Publish mock cluster master node to the server
      let(:cluster_master_node) do
        stub_node(platform: 'ubuntu', version: '16.04') do
          node.automatic['fqdn'] = 'cm.cluster.example.com'
          node.automatic['ipaddress'] = '192.168.0.10'
          node.force_default['dev_mode'] = true
          node.force_default['splunk']['accept_license'] = true
          node.force_default['splunk']['is_server'] = true
          node.force_default['splunk']['mgmt_port'] = '8089'
          node.force_default['splunk']['clustering']['enabled'] = true
          node.force_default['splunk']['clustering']['mode'] = 'master'
          node.force_default['splunk']['clustering']['mgmt_uri'] = 'https://192.168.0.10:8089'
          node.force_default['splunk']['shclustering']['mgmt_uri'] = 'https://192.168.0.10:8089'
        end
      end

      before do
        chef_run_init.node.force_default['splunk']['clustering']['enabled'] = true
        chef_run_init.node.force_default['splunk']['clustering']['mode'] = 'searchhead'
        chef_run_init.create_node(cluster_master_node)
      end

      context 'default settings (single-site)' do
        let(:chef_run) do
          chef_run_init.node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
          chef_run_init.node.run_state['splunk_secret'] = 'notarealsecret'
          chef_run_init
        end

        before do
          chef_run.converge(described_recipe)
        end

        it_performs 'a successful run', '-mode searchhead -master_uri https://192.168.0.10:8089 -replication_port 9887'
      end

      context 'default settings (multi-site)' do
        let(:chef_run) do
          chef_run_init.node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
          chef_run_init.node.run_state['splunk_secret'] = 'notarealsecret'
          chef_run_init.node.force_default['splunk']['clustering']['num_sites'] = 3
          chef_run_init
        end

        before do
          allow_any_instance_of(Chef::Recipe).to receive(:multisite_clustering?).and_return(true)
          chef_run.converge(described_recipe)
        end

        it_performs 'a successful run', '-mode searchhead -site site1 -master_uri https://192.168.0.10:8089 -replication_port 9887'
      end
    end
  end
end
