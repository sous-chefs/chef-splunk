# Inspec tests for enterprise splunk on linux systems.
control 'Disabled Splunk' do
  title 'Verify Splunk is disabled'
  only_if { os.linux? }

  describe.one do
    %w(splunk splunkforwarder).each do |pkg|
      describe package(pkg) do
        it { should_not be_installed }
      end
    end
  end

  describe.one do
    %w(Splunkd SplunkForwarder splunk).each do |svc|
      describe service(svc) do
        it { should_not be_running }
        it { should_not be_enabled }
      end
    end
  end
end
