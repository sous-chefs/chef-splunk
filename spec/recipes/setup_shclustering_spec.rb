require_relative '../spec_helper'

describe 'chef-splunk::setup_shclustering' do
	let(:secrets) do
    {
      'splunk__default' => {
        'id' => 'splunk__default',
        'auth' => 'admin:notarealpassword',
        'secret' => 'notarealsecret'
      }
    }
  end

  let(:deployer_node) do
    stub_node(platform: 'ubuntu', version: '12.04') do |node|
      node.automatic['fqdn'] = 'deploy.cluster.example.com'
      node.automatic['ipaddress'] = '192.168.0.10'
      node.set['dev_mode'] = true
      node.set['splunk']['is_server'] = true
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
end