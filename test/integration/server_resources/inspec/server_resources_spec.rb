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

describe ini('/opt/splunk/etc/apps/chef_splunk_indexes/local/indexes.conf') do
  its('linux_messages_syslog.homePath') { should cmp '$SPLUNK_DB/syslog/db' }
  its('linux_messages_syslog.coldPath') { should cmp '$SPLUNK_DB/syslog/colddb' }
  its('linux_messages_syslog.thawedPath') { should cmp '$SPLUNK_DB/splunk/indexer_thaweddata/syslog/thaweddb' }
  its('linux_messages_syslog.frozenTimePeriodInSecs') { should match /31536000/ }
  its('linux_messages_syslog.repFactor') { should match /auto/ }
end
