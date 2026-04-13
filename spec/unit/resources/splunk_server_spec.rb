# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_server' do
  step_into :splunk_server
  platform 'ubuntu', '24.04'

  context 'action :install with defaults' do
    recipe do
      splunk_server 'default' do
        url 'https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-amd64.deb'
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_splunk_installer('splunk') }
    it { is_expected.to run_execute('update-splunk-mgmt-port').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
    it { is_expected.to run_execute('update-splunk-receiver-port').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
  end

  context 'action :install with custom ports' do
    recipe do
      splunk_server 'custom' do
        url 'https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-amd64.deb'
        mgmt_port 9089
        receiver_port 19997
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_splunk_installer('splunk') }
    it { is_expected.to run_execute('update-splunk-mgmt-port').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
    it { is_expected.to run_execute('update-splunk-receiver-port').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
  end

  context 'action :remove' do
    recipe do
      splunk_server 'default' do
        url 'https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-amd64.deb'
        splunk_auth 'admin:notarealpassword'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_installer('splunk') }
  end
end
