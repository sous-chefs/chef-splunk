control 'Splunk Search Head Deployer' do
  title 'Verify search head deployer provisioning'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe processes(/splunkd.*-p 8089 _internal_launch_under_systemd/) do
      its('users') { should include 'root' }
    end
  end

  describe 'chef-splunk::server should listen on web_port 8000' do
    describe port(8000) do
      it { should be_listening }
    end
  end

  describe 'server config should be configured per node attributes' do
    describe file('/opt/splunk/etc/system/local/server.conf') do
      it { should be_file }
    end
  end
end
