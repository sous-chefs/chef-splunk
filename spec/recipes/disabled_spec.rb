require 'spec_helper'

describe 'chef-splunk::disabled' do
  context 'default attributes' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node, server|
        create_data_bag_item(server, 'vault', 'splunk__default')
        node.force_default['splunk']['disabled'] = true
        allow_any_instance_of(Chef::Recipe).to receive(:splunk_installed?).and_return(true)
        allow_any_instance_of(Chef::Recipe).to receive(:license_accepted?).and_return(true)
      end.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Resource).to receive(:splunk_login_successful?).and_return(false)
    end

    context 'splunk is disabled' do
      let(:message) do
        'The chef-splunk::disabled recipe was added to the node, ' \
        'but the attribute to disable splunk was set to false.'
      end

      it 'included chef-splunk::service' do
        expect(chef_run).to include_recipe('chef-splunk::service')
      end

      it 'disabled splunk boot-start' do
        expect(chef_run).to run_execute('splunk disable boot-start')
        expect(chef_run.execute('splunk disable boot-start')).to notify('service[splunk]').to(:stop).before
      end

      it 'write log debug message' do
        expect(chef_run).to_not write_log('splunk is not disabled').with(level: :debug, message: message)
      end
    end

    context 'splunk is not disabled' do
      it 'logged debug message and returns' do
        expect(chef_run).to_not write_log('splunk is not disabled')
      end
    end
  end
end
