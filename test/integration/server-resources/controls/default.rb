# frozen_string_literal: true

control 'splunk-server-resources-app' do
  title 'Verify splunk_app resource installed the app'
  only_if { os.linux? }

  describe file('/opt/splunk/etc/apps/chef_splunk_universal_forwarder') do
    it { should exist }
    it { should be_directory }
  end
end

control 'splunk-server-resources-index' do
  title 'Verify splunk_index resource created the index'
  only_if { os.linux? }

  describe ini('/opt/splunk/etc/system/local/indexes.conf') do
    its('test_index.homePath') { should cmp '$SPLUNK_DB/test_index/db' }
    its('test_index.coldPath') { should cmp '$SPLUNK_DB/test_index/colddb' }
    its('test_index.thawedPath') { should cmp '$SPLUNK_DB/test_index/thaweddb' }
  end
end
