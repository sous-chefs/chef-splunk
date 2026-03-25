# frozen_string_literal: true

control 'splunk-upgrade-client' do
  title 'Verify Splunk Universal Forwarder upgraded to 9.4.0'
  only_if { os.linux? }

  describe package('splunkforwarder') do
    it { should be_installed }
    its('version') { should match(/9\.4\.0/) }
  end

  describe service('SplunkForwarder') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
