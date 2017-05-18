require_relative '../spec_helper'

describe 'chef-splunk::disabled' do
  context 'splunk is disabled' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.normal['splunk']['disabled'] = true
      end.converge(described_recipe)
    end

    it 'stops the splunk service' do # ~FC005
      expect(chef_run).to stop_service('splunk')
    end

    it 'uninstalls the splunk package' do
      expect(chef_run).to remove_package('splunk')
    end

    it 'uninstalls the splunkforwarder package' do
      expect(chef_run).to remove_package('splunkforwarder')
    end

    it 'disables splunk startup at boot' do
      expect(chef_run).to run_execute('/opt/splunkforwarder/bin/splunk disable boot-start')
    end
  end
end
