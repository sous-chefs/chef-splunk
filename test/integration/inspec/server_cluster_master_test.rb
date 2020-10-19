control 'Splunk Cluster Master' do
  title 'Verify cluster master provisioning'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe processes(/splunkd.*\-p 8089 _internal_launch_under_systemd/) do
      its('users') { should include 'root' }
    end
  end

  describe 'server config should be configured per node attributes' do
    describe file('/opt/splunk/etc/system/local/server.conf') do
      it { should be_file }
    end

    describe ini('/opt/splunk/etc/system/local/server.conf') do
      its('clustering.mode') { should eq 'master' }
      its('clustering.replication_factor') { should match(/\d*/) }
      its('clustering.search_factor') { should match(/\d*/) }
    end
  end
end
