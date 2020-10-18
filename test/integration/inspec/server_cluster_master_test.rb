control 'Splunk Cluster Master' do
  title 'Verify cluster master provisioning'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe command('ps aux | grep "splunkd -p" | head -1 | awk \'{print $1}\'') do
      its(:stdout) { should match(/splunk/) }
    end
  end

  describe 'chef-splunk::server should listen on web_port 8000' do
    describe port(8000) do
      it { should be_listening.with('tcp') }
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
