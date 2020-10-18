require 'spec_helper'

describe 'chef-splunk::disabled' do
  context 'default attributes' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['splunk']['disabled'] = true
      end.converge(described_recipe)
    end

    context 'splunk is disabled' do
      it 'disabled splunk boot-start' do
        expect(chef_run).to run_execute('splunk disable boot-start')
      end

      it 'stopped splunk service' do
        expect(chef_run).to nothing_execute('/opt/splunkforwarder/bin/splunk stop')
        expect(chef_run.execute('/opt/splunkforwarder/bin/splunk stop')).to subscribe_to('execute[splunk disable boot-start]').on(:run).before
      end

      it 'does not log debug message' do
        expect(chef_run).to_not write_log('splunk is not disabled')
      end
    end

    context 'splunk is not disabled' do
      let(:message) do
        'The chef-splunk::disabled recipe was added to the node, ' \
        'but the attribute to disable splunk was set to false.'
      end

      it 'logged debug message and returns' do
        expect(chef_run).to_not write_log('splunk is not disabled')
          .with(level: :debug, message: message)
      end
    end
  end

  context 'splunk server attribute is true' do
    context 'splunk server is disabled' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new do |node|
          node.force_default['splunk']['disabled'] = true
          node.force_default['splunk']['is_server'] = true
        end.converge(described_recipe)
      end

      it 'disabled splunk boot-start' do
        expect(chef_run).to run_execute('splunk disable boot-start')
      end

      it 'stopped splunk service' do
        expect(chef_run).to nothing_execute('/opt/splunk/bin/splunk stop')
        expect(chef_run.execute('/opt/splunk/bin/splunk stop')).to subscribe_to('execute[splunk disable boot-start]').on(:run).before
      end
    end
  end
end
