# frozen_string_literal: true

control 'splunk-disabled' do
  title 'Verify Splunk service is stopped and disabled'
  only_if { os.linux? }

  describe package('splunk') do
    it { should be_installed }
  end

  describe service('Splunkd') do
    it { should_not be_running }
    it { should_not be_enabled }
  end
end
