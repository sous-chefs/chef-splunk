# Simple tests for splunk forwarder on linux systems.

describe package('splunkforwarder') do
  it { should be_installed }
end

describe service('splunk') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

title 'splunk is listening on 8089'
describe port 8089 do
  it { should be_listening }
  its('protocols') { should include('tcp') }
end

describe processes('splunkd') do
  it { should exist }
end
