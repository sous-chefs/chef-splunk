# frozen_string_literal: true

control 'splunk-upgrade-server' do
  title 'Verify Splunk Enterprise upgraded to 9.4.0'
  only_if { os.linux? }

  describe package('splunk') do
    it { should be_installed }
    its('version') { should match(/9\.4\.0/) }
  end

  describe service('Splunkd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
