SPLUNK_HOME = '/opt/splunkforwarder'.freeze
SPLUNK_ENCRYPTED_STRING_REGEX = /\$\d\$.*==$/.freeze

control 'SplunkForwarder installation' do
  title 'SplunkForwarder service installation'

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
  end
end

control 'SplunkForwarder local system config files' do
  title 'SplunkForwarder local system config files'

  %w(inputs.conf outputs.conf server.conf).each do |f|
    describe file("#{SPLUNK_HOME}/etc/system/local/#{f}") do
      it { should be_file }
      it { should exist }
    end
  end

  describe ini("#{SPLUNK_HOME}/etc/system/local/inputs.conf") do
    its('default.host') { should eq 'localhost' }
    its('tcp://:123123.connection_host') { should eq 'dns' }
    its('tcp://:123123.sourcetype') { should eq 'syslog' }
    its('tcp://:123123.source') { should eq 'tcp:123123' }
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

  describe ini("#{SPLUNK_HOME}/etc/system/local/outputs.conf") do
    its('tcpout.defaultGroup') { should eq 'splunk_indexers_9997' }
    its('tcpout.disabled') { should eq 'false' }
    its('tcpout:splunk_indexers_9997.server') { should match(/\:9997$/) }
    its(['tcpout:splunk_indexers_9997', 'forwardedindex.0.whitelist']) { should eq '.*' }
    its(['tcpout:splunk_indexers_9997', 'forwardedindex.1.blacklist']) { should eq '_.*' }
    its(['tcpout:splunk_indexers_9997', 'forwardedindex.2.whitelist']) { should eq '_audit' }
    its(['tcpout:splunk_indexers_9997', 'forwardedindex.filter.disable']) { should eq 'false' }
    its('tcpout:splunk_indexers_9997.sslCertPath') { should eq '$SPLUNK_HOME/etc/certs/cert.pem' }
    its('tcpout:splunk_indexers_9997.sslCommonNameToCheck') { should eq 'sslCommonName' }
    # it won't be the plaintext 'password' per the attribute, and may
    # differ due to salt, just make sure it looks passwordish.
    its('tcpout:splunk_indexers_9997.sslPassword') { should match(SPLUNK_ENCRYPTED_STRING_REGEX) }
    its('tcpout:splunk_indexers_9997.sslRootCAPath') { should eq '$SPLUNK_HOME/etc/certs/cacert.pem' }
    its('tcpout:splunk_indexers_9997.sslVerifyServerCert') { should eq 'false' }
  end
end
