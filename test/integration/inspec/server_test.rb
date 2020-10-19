# Inspec tests for enterprise splunk on linux systems.
SPLUNK_HOME = '/opt/splunk'.freeze
SPLUNK_ENCRYPTED_STRING_REGEX = /\$\d\$.*==$/.freeze

control 'Enterprise Splunk' do
  title 'Verify Enterprise Splunk server installation'
  only_if { os.linux? }

  describe 'chef-splunk::server listening ports' do
    describe port(8089) do
      it { should be_listening }
      its('protocols') { should include('tcp') }
    end
  end

  describe 'verify inputs config' do
    describe file("#{SPLUNK_HOME}/etc/system/local/inputs.conf") do
      it { should be_file }
    end

    describe ini("#{SPLUNK_HOME}/etc/system/local/inputs.conf") do
      its('default.host') { should_not be_nil }
      its('default.host') { should_not be_empty }
    end
  end

  describe package('splunk') do
    it { should be_installed }
  end

  describe.one do
    describe service('splunk') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end

    describe service('Splunkd') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe processes('splunkd') do
    it { should exist }
  end

  describe.one do
    describe file('/etc/systemd/system/Splunkd.service') do
      it { should exist }
      it { should be_file }
    end

    describe file('/etc/init.d/splunk') do
      it { should exist }
      it { should be_file }
    end
  end
end

control 'Splunk admin password validation' do
  title 'Splunk admin password'
  desc 'validate that the splunk admin password has been properly set'
  only_if { os.linux? }

  describe file("#{SPLUNK_HOME}/etc/system/local/user-seed.conf") do
    it { should_not exist }
  end

  describe file("#{SPLUNK_HOME}/etc/system/local/.user-seed.conf") do
    it { should exist }
  end

  # the password used for validation here is from the test/fixture/data_bags/vault/splunk__default.rb
  describe command("#{SPLUNK_HOME}/bin/splunk login -auth admin:notarealpassword") do
    its('stderr') { should be_empty }
    its('exit_status') { should eq 0 }
  end
end
