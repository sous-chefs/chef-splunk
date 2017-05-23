require_relative '../spec_helper'

describe 'chef-splunk::service' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new do |node|
      node.normal['splunk']['accept_license'] = true
    end.converge(described_recipe)
  end

  it 'enables the service at boot and accepts the license' do
    stub_command('grep -q -- \'--no-prompt --answer-yes\' /etc/init.d/splunk').and_return(false)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/opt/splunkforwarder/ftr').and_return(true)
    expect(chef_run).to run_execute('/opt/splunkforwarder/bin/splunk enable boot-start --accept-license --answer-yes')
  end

  it 'starts the splunk service' do
    stub_command('grep -q -- \'--no-prompt --answer-yes\' /etc/init.d/splunk').and_return(true)
    expect(chef_run).to start_service('splunk')
  end
end
