require 'spec_helper'

describe 'chef-splunk::setup_shclustering' do
  let(:secrets) do
    {
      'splunk__default' => {
        'id' => 'splunk__default',
        'auth' => 'admin:notarealpassword',
        'secret' => 'notarealsecret',
      },
    }
  end

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

  context 'search head cluster member settings' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['shclustering']['enabled'] = true
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['shclustering']['deployer_url'] = "https://#{deployer_node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['fqdn']}:8089"
        node.force_default['splunk']['shclustering']['shcluster_members'] = [
          'https://shcluster-member01:8089',
          'https://shcluster-member02:8089',
          'https://shcluster-member03:8089',
        ]
        # Populate mock vault data bag to the server
        server.create_data_bag('vault', secrets)
      end.converge(described_recipe)
    end

    it 'includes chef-vault' do
      expect(chef_run).to include_recipe('chef-vault::default')
    end

    it 'writes a file marker to ensure convergence' do
      expect(chef_run).to render_file('/opt/splunk/etc/.setup_shcluster').with_content('true\n')
    end

    it 'writes server.conf with replication port' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("[replication_port://#{chef_run.node['splunk']['shclustering']['replication_port']}]")
    end

    it 'writes server.conf with a shclustering stanza' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content('[shclustering]')
    end

    it 'writes server.conf with the deployer url' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("conf_deploy_fetch_url = #{chef_run.node['splunk']['shclustering']['deployer_url']}")
    end

    it 'writes server.conf with the node mgmt uri' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("mgmt_uri = #{chef_run.node['splunk']['shclustering']['mgmt_uri']}")
    end

    it 'writes server.conf with the shcluster replication factor' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("replication_factor = #{chef_run.node['splunk']['shclustering']['replication_factor']}")
    end

    it 'writes server.conf with the shcluster label' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("shcluster_label = #{chef_run.node['splunk']['shclustering']['label']}")
    end

    it 'writes server.conf with the shcluster secret' do
      expect(chef_run).to render_file('/opt/splunk/etc/apps/0_autogen_shcluster_config/local/server.conf')
        .with_content("pass4SymmKey = #{secrets['splunk__default']['secret']}")
    end

    it 'does not run command to bootstrap captain' do
      expect(chef_run).to_not run_execute('bootstrap-shcluster')
    end

    context 'while set to captain mode' do
      context 'during initial chef run' do
        before(:each) do
          chef_run.node.force_default['splunk']['shclustering']['mode'] = 'captain'
          allow_any_instance_of(::File).to receive(:exist?).and_call_original
          allow_any_instance_of(::File).to receive(:exist?)
            .with('/opt/splunk/etc/.setup_shcluster').and_return(false)
          chef_run.converge(described_recipe)
        end

        let(:shcluster_servers_list) do
          chef_run.node.force_default['splunk']['shclustering']['shcluster_members'].join(';')
        end

        it 'runs command to bootstrap captain with correct parameters' do
          expect(chef_run).to run_execute('bootstrap-shcluster').with(
            'command' => "/opt/splunk/bin/splunk bootstrap shcluster-captain -servers_list '#{shcluster_servers_list}' \
-auth '#{secrets['splunk__default']['auth']}'"
          )
          expect(chef_run.execute('bootstrap-shcluster')).to notify('service[splunk]').to(:restart)
        end
      end
    end
  end
end
