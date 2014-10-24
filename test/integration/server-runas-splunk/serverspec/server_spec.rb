require 'spec_helper'

describe 'chef-splunk::server should run as "splunk" user' do
  describe command('ps aux | grep "splunkd -p" | head -1 | awk \'{print $1}\'') do
    its(:stdout) { should match(/splunk/) }
  end
end

describe 'chef-splunk::server should listen on web_port 8443' do
  describe port(8443) do
    it { should be_listening.with('tcp') }
  end
end
