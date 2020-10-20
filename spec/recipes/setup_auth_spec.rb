require 'spec_helper'

describe 'chef-splunk::setup_auth' do
  context 'default attributes' do
    let(:runner) do
      ChefSpec::ServerRunner.new do |node, server|
        create_data_bag_item(server, 'vault', 'splunk__default')
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['accept_license'] = true
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
      end
    end

    context 'setup_auth is true' do
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

      before do
        allow_any_instance_of(Chef::Resource).to receive(:splunk_login_successful?).and_return(false)
      end

      it 'created user-seed.conf' do
        expect(chef_run).to create_file('user-seed.conf').with(mode: '0640')
      end

      it 'created .user-seed.conf only when notified after user-seed.conf is processed' do
        expect(chef_run).to nothing_file('.user-seed.conf')
        expect(chef_run.file('.user-seed.conf')).to subscribe_to('file[user-seed.conf]').on(:touch).immediately
      end
    end

    context 'setup auth is false' do
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

      before do
        runner.node.force_default['splunk']['setup_auth'] = false
      end

      it 'logs debug message' do
        expect(chef_run).to write_log('setup_auth is disabled').with(level: :debug)
      end
    end
  end
end
