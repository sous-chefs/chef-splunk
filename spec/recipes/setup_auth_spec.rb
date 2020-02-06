require 'spec_helper'

describe 'chef-splunk::setup_auth' do
  context 'default attributes' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, _server|
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['splunk']['accept_license'] = true
        node.run_state['splunk_auth_info'] = 'admin:notarealpassword'
        node.run_state['splunk_secret'] = 'notarealsecret'
      end
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return('auth' => 'admin:notarealpassword')
    end

    context 'setup_auth is true' do
      it 'created user-seed.conf and notifies splunk restart' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_template('user-seed.conf')
          .with(mode: '600', sensitive: true, owner: 'root', group: 'root')
        expect(chef_run.template('user-seed.conf')).to notify('service[splunk]').to(:restart).immediately
      end

      it 'created .user-seed.conf' do
        chef_run.converge(described_recipe)
        expect(chef_run).to create_file('.user-seed.conf')
          .with(mode: '600', owner: 'root', group: 'root')
      end
    end

    context 'setup auth is false' do
      it 'logs debug message' do
        chef_run.node.force_default['splunk']['setup_auth'] = false
        chef_run.converge(described_recipe)
        expect(chef_run).to write_log('setup_auth is disabled').with(level: :debug)
      end
    end
  end
end
