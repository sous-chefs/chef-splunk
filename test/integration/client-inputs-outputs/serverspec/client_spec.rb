require 'spec_helper'

describe 'inputs config should be configured per node attributes' do
  describe file('/opt/splunkforwarder/etc/system/local/inputs.conf') do
    it { should be_file }
    its(:content) { should match(/\[tcp:\/\/:123123\]/) }
    its(:content) { should match(/connection_host = dns/) }
    its(:content) { should match(/sourcetype = syslog/) }
    its(:content) { should match(/source = tcp:123123/) }
  end
end

describe 'outputs config should be configured per node attributes' do
  describe file('/opt/splunkforwarder/etc/system/local/outputs.conf') do
    it { should be_file }
    its(:content) { should match(/defaultGroup = splunk_indexers_9997/) }
    # from the default attributes
    its(:content) { should match(/forwardedindex.0.whitelist = .*/) }
    its(:content) { should match(/forwardedindex.1.blacklist = _.*/) }
    its(:content) { should match(/forwardedindex.2.whitelist = _audit/) }
    its(:content) { should match(/forwardedindex.filter.disable = false/) }
    # servers
    its(:content) { should match(/server = server-ubuntu-1204.vagrantup.com:9997/) }
    # attributes for dynamic definition
    its(:content) { should match(/sslCertPath = \$SPLUNK_HOME\/etc\/certs\/cert.pem/) }
    its(:content) { should match(/sslCommonNameToCheck = sslCommonName/) }
    # it won't be the plaintext 'password' per the attribute, and may
    # differ due to salt, just make sure it looks passwordish.
    its(:content) { should match(/sslPassword = \$1/) }
    its(:content) { should match(/sslRootCAPath = \$SPLUNK_HOME\/etc\/certs\/cacert.pem/) }
    its(:content) { should match(/sslVerifyServerCert = false/) }
  end
end
