# frozen_string_literal: true

SPLUNK_HOME = '/opt/splunkforwarder'

control 'splunk-default-installation' do
  title 'Verify Splunk Universal Forwarder default installation'
  only_if { os.linux? }

  if file("#{SPLUNK_HOME}/bin/splunk").exist?
    describe file("#{SPLUNK_HOME}/bin/splunk") do
      it { should be_file }
    end
  else
    describe package('splunkforwarder') do
      it { should be_installed }
    end
  end

  describe service('SplunkForwarder') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/usr/lib/systemd/system/SplunkForwarder.service') do
    it { should exist }
    it { should be_file }
  end

  describe user('splunk') do
    it { should exist }
  end

  describe group('splunk') do
    it { should exist }
  end
end

control 'splunk-default-outputs' do
  title 'Verify outputs.conf configuration'
  only_if { os.linux? }

  describe file("#{SPLUNK_HOME}/etc/system/local/outputs.conf") do
    it { should be_file }
  end
end
