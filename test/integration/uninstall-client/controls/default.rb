# frozen_string_literal: true

control 'splunk-forwarder-removed' do
  title 'Verify Splunk Universal Forwarder has been removed'
  only_if { os.linux? }

  describe file('/opt/splunkforwarder') do
    it { should_not exist }
  end
end
