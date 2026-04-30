# frozen_string_literal: true

control 'splunk-upgrade-client' do
  title 'Verify Splunk Universal Forwarder upgraded to 10.0.5'
  only_if { os.linux? }

  if file('/opt/splunkforwarder/bin/splunk').exist?
    describe file('/opt/splunkforwarder/bin/splunk') do
      it { should be_file }
    end
  else
    describe package('splunkforwarder') do
      it { should be_installed }
      its('version') { should match(/10\.0\.5/) }
    end
  end

  describe service('SplunkForwarder') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
