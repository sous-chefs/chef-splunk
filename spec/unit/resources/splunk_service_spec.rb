# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_service' do
  step_into :splunk_service
  platform 'ubuntu', '24.04'

  context 'action :start for a server' do
    recipe do
      splunk_service 'splunk' do
        install_dir '/opt/splunk'
        runas_user 'splunk'
        service_name 'Splunkd'
        admin_password 'notarealpassword'
        action :start
      end
    end

    it { is_expected.to create_directory('/opt/splunk').with(owner: 'splunk', group: 'splunk', mode: '755') }
    it { is_expected.to create_directory('/opt/splunk/var').with(owner: 'splunk', group: 'splunk', mode: '711') }
    it { is_expected.to create_directory('/opt/splunk/var/log').with(owner: 'splunk', group: 'splunk', mode: '711') }
    it { is_expected.to create_directory('/opt/splunk/var/log/splunk').with(owner: 'splunk', group: 'splunk', mode: '700') }
    it { is_expected.to run_execute('splunk enable boot-start').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
    it { is_expected.to create_link('/etc/systemd/system/splunk.service') }
    it { is_expected.to enable_service('splunk') }
    it { is_expected.to start_service('splunk') }
  end

  context 'action :stop' do
    recipe do
      splunk_service 'splunk' do
        install_dir '/opt/splunkforwarder'
        service_name 'SplunkForwarder'
        action :stop
      end
    end

    it { is_expected.to stop_service('splunk') }
    it { is_expected.to disable_service('splunk') }
  end
end
