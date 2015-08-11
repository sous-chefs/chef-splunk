require 'spec_helper'

describe 'splunk apps should be installed and enabled' do
  describe file('/opt/splunk/etc/apps/bistro-1.0.2') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'splunk' }
  end
  describe command("/opt/splunk/bin/splunk btool --debug --app=bistro-1.0.2 app list") do
    it 'should enable the app' do
      expect(:stdout).to match(/disabled\s*=\s*(0|false)/)
    end
  end
end
