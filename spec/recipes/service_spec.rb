require 'spec_helper'

describe 'chef-splunk::service' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new do |node|
      node.force_default['splunk']['accept_license'] = true
    end.converge(described_recipe)
  end

  it 'enables the service at boot and accepts the license' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/ftr').and_return(true)
    expect(chef_run).to run_execute('/opt/splunkforwarder/bin/splunk enable boot-start --answer-yes --no-prompt --accept-license')
  end

  it 'starts the splunk service' do
    expect(chef_run).to start_service('splunk')
  end
end
