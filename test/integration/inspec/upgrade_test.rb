# Inspec tests for enterprise splunk on linux systems.
SPLUNK_HOME = '/opt/splunk'.freeze
SPLUNK_ENCRYPTED_STRING_REGEX = /\$\d\$.*==$/.freeze

control 'Splunk Upgrade' do
  title 'Verify Splunk upgrade to 8.0.6'
  only_if { os.linux? }

  describe.one do
    describe package('splunkforwarder') do
      it { should be_installed }
      its('version') { should match(/8\.0\.6/) }
    end

    describe package('splunk') do
      it { should be_installed }
      its('version') { should match(/8\.0\.6/) }
    end
  end

  describe.one do
    %w(Splunkd SplunkForwarder splunk).each do |svc|
      describe service(svc) do
        it { should be_installed }
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
end
