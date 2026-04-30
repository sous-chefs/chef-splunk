# frozen_string_literal: true

control 'splunk-disabled' do
  title 'Verify Splunk service is stopped and disabled'
  only_if { os.linux? }

  if file('/opt/splunk/bin/splunk').exist?
    describe file('/opt/splunk/bin/splunk') do
      it { should be_file }
    end
  else
    describe package('splunk') do
      it { should be_installed }
    end
  end

  describe service('Splunkd') do
    it { should_not be_running }
    it { should_not be_enabled }
  end
end
