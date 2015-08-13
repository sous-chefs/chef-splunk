require 'spec_helper'

describe 'splunk apps should be installed and enabled' do
  describe file('/opt/splunkforwarder/etc/apps/bistro-1.0.2') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'splunk' }
  end
  describe command("/opt/splunkforwarder/bin/splunk btool --app=bistro-1.0.2 app list") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match /disabled\s*=\s*(0|false)/ }
  end
end
