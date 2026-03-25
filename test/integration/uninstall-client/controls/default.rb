# frozen_string_literal: true

control 'splunk-forwarder-removed' do
  title 'Verify Splunk Universal Forwarder has been removed'
  only_if { os.linux? }

  describe package('splunkforwarder') do
    it { should_not be_installed }
  end
end
