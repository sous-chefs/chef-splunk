control 'Splunk Cluster Master' do
  title 'Verify cluster master provisioning'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe processes(/splunkd/) do
      it { should exist }
      its('users') { should_not include 'splunk' }
      its('users') { should include 'root' }
    end
  end

  describe ini('/opt/splunk/etc/system/local/inputs.conf') do
    its('default.host') { should_not be_nil }
    its('default.host') { should_not be_empty }
  end

  describe file('/opt/splunk/etc/system/local/server.conf') do
    it { should be_file }
  end

  describe ini('/opt/splunk/etc/system/local/server.conf') do
    its('clustering.mode') { should eq 'master' }
    its('clustering.replication_factor') { should match(/\d*/) }
    its('clustering.search_factor') { should match(/\d*/) }
  end
end
