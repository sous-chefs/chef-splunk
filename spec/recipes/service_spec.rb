require_relative '../spec_helper'

describe 'chef-splunk::service' do
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['splunk']['accept_license'] = true
    end.converge(described_recipe)
  end

  it 'enables the service at boot and accepts the license' do
    expect(chef_run).to run_execute('/opt/splunkforwarder/bin/splunk enable boot-start --accept-license --answer-yes')
  end

  it 'starts the splunk service' do
    expect(chef_run).to start_service('splunk')
  end
end
