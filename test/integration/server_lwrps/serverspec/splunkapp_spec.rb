require 'spec_helper'

describe 'splunk apps should be installed and enabled' do
  describe file('/opt/splunk/etc/apps/bistro-1.0.2') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'splunk' }
  end
  describe command('/opt/splunk/bin/splunk btool --app=bistro-1.0.2 app list') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match /disabled\s*=\s*(0|false)/ }
  end
  describe file('/opt/splunk/etc/apps/chef_sample_local_app_test') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'splunk' }
  end
  describe command('/opt/splunk/bin/splunk btool --app=chef_sample_local_app_test app list') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match /disabled\s*=\s*(0|false)/ }
  end
  describe file('/opt/splunk/etc/apps/chef_sample_local_app_test/appserver/static/chefsuccess.txt') do
    it { should exist }
    its('content') { should eq 'If you can read this, the app was successfully installed!' }
  end
end
