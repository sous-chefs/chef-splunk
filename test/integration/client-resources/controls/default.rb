# frozen_string_literal: true

control 'splunk-client-resources-app' do
  title 'Verify splunk_app resource installed the app'
  only_if { os.linux? }

  describe file('/opt/splunkforwarder/etc/apps/chef_splunk_universal_forwarder') do
    it { should exist }
    it { should be_directory }
  end
end

control 'splunk-client-resources-monitor' do
  title 'Verify splunk_monitor resource configured inputs'
  only_if { os.linux? }

  describe ini('/opt/splunkforwarder/etc/system/local/inputs.conf') do
    its(['monitor:///var/log', 'index']) { should cmp 'default' }
    its(['monitor:///var/log', 'sourcetype']) { should cmp 'syslog' }
  end
end
