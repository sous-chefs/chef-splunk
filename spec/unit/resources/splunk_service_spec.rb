# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_service' do
  step_into :splunk_service
  platform 'ubuntu', '24.04'

  context 'action :start for a server' do
    before do
      allow(Etc).to receive(:getpwnam).and_call_original
      allow(Etc).to receive(:getpwnam).with('splunk').and_return(double(uid: 1234))
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/opt/splunk').and_return(true)
      allow(File).to receive(:exist?).with('/opt/splunk/bin/splunk').and_return(true)
      allow(File).to receive(:stat).and_call_original
      allow(File).to receive(:stat).with('/opt/splunk').and_return(double(uid: 0))
      allow(File).to receive(:stat).with('/opt/splunk/bin/splunk').and_return(double(uid: 0))
    end

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
    it { is_expected.to run_execute('chown /opt/splunk').with(command: 'chown -R splunk:splunk /opt/splunk') }
    it { is_expected.to create_directory('/opt/splunk/var').with(owner: 'splunk', group: 'splunk', mode: '711') }
    it { is_expected.to create_directory('/opt/splunk/var/log').with(owner: 'splunk', group: 'splunk', mode: '711') }
    it { is_expected.to create_directory('/opt/splunk/var/log/splunk').with(owner: 'splunk', group: 'splunk', mode: '700') }
    it do
      is_expected.to run_execute('splunk enable boot-start')
        .with(
          command: '/opt/splunk/bin/splunk enable boot-start -user splunk -systemd-managed 1 --accept-license --seed-passwd "$SPLUNK_PASSWORD" --answer-yes --no-prompt',
          environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }
        )
    end
    it { is_expected.to nothing_execute('systemctl daemon-reload') }
    it { is_expected.to enable_service('Splunkd') }
    it { is_expected.to start_service('Splunkd') }
  end

  context 'action :start with optimistic file locking' do
    before do
      allow(Etc).to receive(:getpwnam).and_call_original
      allow(Etc).to receive(:getpwnam).with('splunk').and_return(double(uid: 1234))
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/opt/splunk').and_return(true)
      allow(File).to receive(:exist?).with('/opt/splunk/bin/splunk').and_return(true)
      allow(File).to receive(:stat).and_call_original
      allow(File).to receive(:stat).with('/opt/splunk').and_return(double(uid: 1234))
      allow(File).to receive(:stat).with('/opt/splunk/bin/splunk').and_return(double(uid: 1234))
    end

    recipe do
      splunk_service 'splunk' do
        install_dir '/opt/splunk'
        runas_user 'splunk'
        service_name 'Splunkd'
        optimistic_file_locking true
        action :start
      end
    end

    it { is_expected.to run_ruby_block('enable optimistic file locking') }
    it { is_expected.to create_directory('/etc/systemd/system/Splunkd.service.d').with(mode: '755') }
    it do
      is_expected.to create_file('/etc/systemd/system/Splunkd.service.d/chef-splunk.conf')
        .with(content: "[Service]\nEnvironment=OPTIMISTIC_ABOUT_FILE_LOCKING=1\n", mode: '644')
    end
  end

  context 'action :stop' do
    recipe do
      splunk_service 'splunk' do
        install_dir '/opt/splunkforwarder'
        service_name 'SplunkForwarder'
        action :stop
      end
    end

    it { is_expected.to stop_service('SplunkForwarder') }
    it { is_expected.to disable_service('SplunkForwarder') }
  end
end
