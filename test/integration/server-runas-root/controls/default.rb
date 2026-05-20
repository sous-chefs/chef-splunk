# frozen_string_literal: true

# Inspec tests for enterprise splunk on linux systems.
SPLUNK_HOME = '/opt/splunk'

control 'Enterprise Splunk' do
  title 'Verify Enterprise Splunk server installation'
  only_if { os.linux? }

  describe 'chef-splunk::server should run as "root" user' do
    describe processes(/splunkd.*-p 8089 _internal_launch_under_systemd/) do
      its('users') { should include 'root' }
    end
  end

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
      its('splunktcp://9997.disabled') { should cmp '0' }
    end
  end

  if file("#{SPLUNK_HOME}/bin/splunk").exist?
    describe file("#{SPLUNK_HOME}/bin/splunk") do
      it { should be_file }
    end
  else
    describe package('splunk') do
      it { should be_installed }
    end
  end

  describe service('Splunkd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe.one do
    describe processes(Regexp.new('splunkd.*-p 8089 _internal_launch_under_systemd')) do
      its('users') { should include 'splunk' }
      its('users') { should_not include 'root' }
      it { should exist }
    end
    describe processes(Regexp.new('splunkd.*-p 8089 _internal_launch_under_systemd')) do
      its('users') { should include 'root' }
      it { should exist }
    end
  end

  describe.one do
    describe file('/usr/lib/systemd/system/Splunkd.service') do
      it { should exist }
      it { should be_file }
    end

    describe file('/etc/systemd/system/Splunkd.service') do
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
    it { should exist }
    its('content') { should match(/USERNAME = admin/) }
  end

  # Splunk emits certificate warnings to stderr on successful CLI login in
  # containerized test runs, so exit status is the useful assertion here.
  describe command("#{SPLUNK_HOME}/bin/splunk login -auth admin:notarealpassword") do
    its('exit_status') { should eq 0 }
  end
end
