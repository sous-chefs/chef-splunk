# Inspec tests for splunk forwarder on linux systems.
SPLUNK_HOME = '/opt/splunkforwarder'.freeze
SPLUNK_ENCRYPTED_STRING_REGEX = /\$\d\$.*==$/.freeze

control 'Splunk Universal Forwarder' do
  title 'Verify Splunk Universal Forwarder installation'
  only_if { os.linux? }

  describe 'verify inputs config' do
    describe file("#{SPLUNK_HOME}/etc/system/local/inputs.conf") do
      it { should be_file }
    end

    describe ini("#{SPLUNK_HOME}/etc/system/local/inputs.conf") do
      its('default.host') { should_not be_nil }
      its('default.host') { should_not be_empty }
    end
  end

  describe 'verify outputs config' do
    describe file("#{SPLUNK_HOME}/etc/system/local/outputs.conf") do
      it { should be_file }
    end

    describe ini("#{SPLUNK_HOME}/etc/system/local/outputs.conf") do
      its('tcpout.defaultGroup') { should eq 'splunk_indexers_9997' }
      its('tcpout.disabled') { should eq 'false' }
      its('tcpout:splunk_indexers_9997.server') { should_not be_empty }
      its('tcpout:splunk_indexers_9997.server') { should_not be_nil }
      its(['tcpout:splunk_indexers_9997', 'forwardedindex.0.whitelist']) { should eq '.*' }
      its(['tcpout:splunk_indexers_9997', 'forwardedindex.1.blacklist']) { should eq '_.*' }
      its(['tcpout:splunk_indexers_9997', 'forwardedindex.2.whitelist']) { should eq '_audit' }
      its(['tcpout:splunk_indexers_9997', 'forwardedindex.filter.disable']) { should eq 'false' }
    end
  end

  describe 'verify server config' do
    describe file("#{SPLUNK_HOME}/etc/system/local/server.conf") do
      it { should be_file }
      it { should exist }
    end

    describe ini("#{SPLUNK_HOME}/etc/system/local/server.conf") do
      its('general.serverName') { should_not be_empty }
      its('general.serverName') { should_not be_nil }
      its('general.pass4SymmKey') { should match(SPLUNK_ENCRYPTED_STRING_REGEX) }
      its('sslConfig.sslPassword') { should match(SPLUNK_ENCRYPTED_STRING_REGEX) }
      its('lmpool:auto_generated_pool_forwarder.description') { should eq 'auto_generated_pool_forwarder' }
      its('lmpool:auto_generated_pool_forwarder.quota') { should eq 'MAX' }
      its('lmpool:auto_generated_pool_forwarder.slaves') { should eq '*' }
      its('lmpool:auto_generated_pool_forwarder.stack_id') { should eq 'forwarder' }
      its('lmpool:auto_generated_pool_free.description') { should eq 'auto_generated_pool_free' }
      its('lmpool:auto_generated_pool_free.quota') { should eq 'MAX' }
      its('lmpool:auto_generated_pool_free.slaves') { should eq '*' }
      its('lmpool:auto_generated_pool_free.stack_id') { should eq 'free' }
    end
  end

  describe package('splunkforwarder') do
    it { should be_installed }
  end

  describe.one do
    describe service('splunk') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end

    describe service('SplunkForwarder') do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe port 8089 do
    it { should_not be_listening }
  end

  describe processes('splunkd') do
    it { should exist }
    its('users') { should_not include 'root' }
    its('users') { should include 'splunk' }
  end

  describe.one do
    describe file('/etc/systemd/system/SplunkForwarder.service') do
      it { should exist }
      it { should be_file }
    end

    describe file('/etc/init.d/splunk') do
      it { should exist }
      it { should be_file }
    end
  end
end
