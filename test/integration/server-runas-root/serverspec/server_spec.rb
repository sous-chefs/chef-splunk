require 'spec_helper'

describe 'chef-splunk::server should run as "root" user' do
  describe command('ps aux | grep "splunkd -p" | head -1 | awk \'{print $1}\'') do
    its(:stdout) { should match(/root/) }
  end
end

describe 'chef-splunk::server should listen on web_port 443' do
  describe port(443) do
    it { should be_listening.with('tcp') }
  end
end
