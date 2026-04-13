# frozen_string_literal: true

control 'splunk-upgrade-server' do
  title 'Verify Splunk Enterprise upgraded to 9.4.0'
  only_if { os.linux? }

  if file('/opt/splunk/bin/splunk').exist?
    describe file('/opt/splunk/bin/splunk') do
      it { should be_file }
    end
  else
    describe package('splunk') do
      it { should be_installed }
      its('version') { should match(/9\.4\.0/) }
    end
  end

  describe service('Splunkd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
