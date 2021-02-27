control 'Custom Resources' do
  title 'Verify custom resources provided by this cookbook'
  only_if { os.linux? }

  describe.one do
    describe file('/opt/splunkforwarder/etc/apps/bistro-1.0.2') do
      it { should exist }
      it { should be_directory }
    end
    describe file('/opt/splunk/etc/apps/bistro-1.0.2') do
      it { should exist }
      it { should be_directory }
    end
  end

  describe.one do
    describe command('/opt/splunkforwarder/bin/splunk btool --app=bistro-1.0.2 app list') do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not match /disabled\s*=\s*(0|false)/ }
    end
    describe command('/opt/splunk/bin/splunk btool --app=bistro-1.0.2 app list') do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not match /disabled\s*=\s*(0|false)/ }
    end
  end
end

describe ini('/opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/default/inputs.conf') do
  its(['monitor:///var/log/httpd/access.log', 'index']) { should cmp /access_combined/ }
  its(['monitor:///var/log/httpd/access.log', 'sourcetype']) { should match /access_combined/ }
end
