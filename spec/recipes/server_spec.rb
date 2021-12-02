require 'spec_helper'

describe 'chef-splunk::server' do
  let(:runner) do
    ChefSpec::ServerRunner.new do |node|
      node.force_default['dev_mode'] = true
      node.force_default['splunk']['accept_license'] = true
      node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
      node.run_state['splunk_secret'] = 'notarealsecret'
    end
  end

  before(:each) do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(true)
    allow_any_instance_of(Chef::Resource).to receive(:current_mgmt_port).and_return('8089')
    allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return('auth' => 'admin:notarealpassword')
  end

  context 'default settings' do
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

    it 'does not update splunkd management port' do
      expect(chef_run).to_not run_execute('update-splunk-mgmt-port')
    end

    it 'enables receiver port' do
      expect(chef_run).to run_ruby_block('enable-splunk-receiver-port').with(sensitive: true)
    end
  end

  context 'custom management port' do
    # since the service[splunk] resource is created in the chef-splunk cookbook and
    # the `include_recipe` is mocked in this chefspec, we need to insert
    # a generic mock-up into the Resource collection so notifications can be checked
    cached(:chef_run) do
      runner.node.force_default['dev_mode'] = true
      runner.node.force_default['splunk']['accept_license'] = true
      runner.node.force_default['splunk']['mgmt_port'] = '9089'
      runner.converge(described_recipe) do
        runner.resource_collection.insert(
          Chef::Resource::Service.new('splunk', runner.run_context)
        )
      end
    end

    before do
      allow_any_instance_of(Chef::Resource).to receive(:port_open?).and_return(false)
    end

    it 'updates splunkd management port' do
      expect(chef_run).to run_execute('update-splunk-mgmt-port').with(
        command: "/opt/splunk/bin/splunk set splunkd-port 9089 -auth 'admin:notarealpassword' --accept-license",
        sensitive: true
      )
    end

    it 'notifies the splunk service to restart when changing management port' do
      execution = chef_run.execute('update-splunk-mgmt-port')
      expect(execution).to notify('service[splunk]').to(:restart)
    end

    it 'enables receiver port' do
      expect(chef_run).to run_ruby_block('enable-splunk-receiver-port').with(sensitive: true)
    end
  end
end
