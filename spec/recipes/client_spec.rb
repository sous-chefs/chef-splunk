require 'spec_helper'

describe 'chef-splunk::client' do
  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
  end

  context 'client config with remote indexers managed by Chef server' do
    let(:splunk_indexer1) do
      stub_node('idx1', platform: 'ubuntu', version: '20.04') do |node|
        node.automatic['fqdn'] = 'idx1.example.com'
        node.automatic['ipaddress'] = '10.10.15.43'
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['receiver_port'] = '1648'
        node.force_default['splunk']['server']['runasroot'] = false
      end
    end

    let(:splunk_indexer2) do
      stub_node('idx2', platform: 'ubuntu', version: '20.04') do |node|
        node.automatic['hostname'] = 'spelunker'
        node.automatic['fqdn'] = 'idx2.example.com'
        node.automatic['ipaddress'] = '10.10.15.45'
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['receiver_port'] = '1648'
        node.force_default['splunk']['server']['runasroot'] = false
      end
    end

    cached(:runner) do
      ChefSpec::ServerRunner.new do |node, server|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['server']['runasroot'] = false
        node.force_default['splunk']['accept_license'] = true
        # Publish mock indexer nodes to the server
        server.create_node(splunk_indexer1)
        server.create_node(splunk_indexer2)
      end
    end

    # since the service[splunk] resource is created in the chef-splunk cookbook and
    # the `include_recipe` is mocked in this chefspec, we need to insert
    # a generic mock-up into the Resource collection so notifications can be checked
    let(:chef_run) do
      runner.converge(described_recipe) do
        runner.resource_collection.insert(
          Chef::Resource::Service.new('splunk', runner.run_context)
        )
      end
    end

    it 'creates the local system directory' do
      expect(chef_run).to create_directory('/opt/splunkforwarder/etc/system/local').with(
        'recursive' => true,
        'owner' => 'splunk',
        'group' => 'splunk'
      )
    end

    it 'creates an outputs template in the local system directory' do
      expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/outputs.conf')
    end

    it 'writes outputs.conf with tcpout server list from Chef search' do
      server_list = [splunk_indexer1, splunk_indexer2].map do |s|
        s['fqdn'] + ':' + s['splunk']['receiver_port']
      end.join(', ')
      expect(chef_run).to render_file('/opt/splunkforwarder/etc/system/local/outputs.conf')
        .with_content("server = #{server_list}")
    end

    it 'notifies the splunk service to restart when rendering the outputs template' do
      resource = chef_run.template('/opt/splunkforwarder/etc/system/local/outputs.conf')
      expect(resource).to notify('service[splunk]').to(:restart)
    end

    it 'created app chef_splunk_universal_forwarder' do
      expect(chef_run).to install_splunk_app('chef_splunk_universal_forwarder')
      expect(chef_run.splunk_app('chef_splunk_universal_forwarder')).to notify('service[splunk]').to(:restart)
    end
  end

  context 'client config with remote indexers statically defined' do
    cached(:runner) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['server_list'] = 'indexers.splunkcloud.com:9997'
        node.force_default['splunk']['server']['runasroot'] = false
        node.force_default['splunk']['accept_license'] = true
      end
    end

    # since the service[splunk] resource is created in the chef-splunk cookbook and
    # the `include_recipe` is mocked in this chefspec, we need to insert
    # a generic mock-up into the Resource collection so notifications can be checked
    cached(:chef_run) do
      runner.converge(described_recipe) do
        runner.resource_collection.insert(
          Chef::Resource::Service.new('splunk', runner.run_context)
        )
      end
    end

    it 'creates the local system directory' do
      expect(chef_run).to create_directory('/opt/splunkforwarder/etc/system/local').with(
        'recursive' => true,
        'owner' => 'splunk',
        'group' => 'splunk'
      )
    end

    it 'creates an outputs template in the local system directory' do
      expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/outputs.conf')
    end

    it 'writes outputs.conf with tcpout server list from node attribute' do
      expect(chef_run).to render_file('/opt/splunkforwarder/etc/system/local/outputs.conf')
        .with_content('server = indexers.splunkcloud.com:9997')
    end

    it 'notifies the splunk service to restart when rendering the outputs template' do
      resource = chef_run.template('/opt/splunkforwarder/etc/system/local/outputs.conf')
      expect(resource).to notify('service[splunk]').to(:restart)
    end

    it 'created app chef_splunk_universal_forwarder' do
      expect(chef_run).to install_splunk_app('chef_splunk_universal_forwarder')
      expect(chef_run.splunk_app('chef_splunk_universal_forwarder')).to notify('service[splunk]').to(:restart)
    end
  end

  context 'client inputs config has hosts' do
    cached(:runner) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['inputs_conf']['host'] = 'localhost'
        node.force_default['splunk']['accept_license'] = true
      end
    end

    # since the service[splunk] resource is created in the chef-splunk cookbook and
    # the `include_recipe` is mocked in this chefspec, we need to insert
    # a generic mock-up into the Resource collection so notifications can be checked
    cached(:chef_run) do
      runner.converge(described_recipe) do
        runner.resource_collection.insert(
          Chef::Resource::Service.new('splunk', runner.run_context)
        )
      end
    end

    it 'creates an inputs template in the local system directory if it has hosts' do
      expect(chef_run).to create_template('/opt/splunkforwarder/etc/system/local/inputs.conf')
    end

    it 'notifies the splunk service to restart when rendering the inputs template' do
      resource = chef_run.template('/opt/splunkforwarder/etc/system/local/inputs.conf')
      expect(resource).to notify('service[splunk]').to(:restart)
    end

    it 'created app chef_splunk_universal_forwarder' do
      expect(chef_run).to install_splunk_app('chef_splunk_universal_forwarder')
      expect(chef_run.splunk_app('chef_splunk_universal_forwarder')).to notify('service[splunk]').to(:restart)
    end
  end
end
