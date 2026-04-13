# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_installer' do
  step_into :splunk_installer
  platform 'ubuntu', '24.04'

  context 'action :run' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
  end

  context 'action :run with version' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
        version '10.0.5'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
  end

  context 'action :upgrade' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
        action :upgrade
      end
    end

    it { is_expected.to upgrade_splunk_installer('splunkforwarder') }
  end

  context 'action :remove' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_installer('splunkforwarder') }
  end

  context 'action :run with tgz' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
    it { is_expected.to create_remote_file('splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz') }
    it { is_expected.to run_execute('extract splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz') }
  end

  context 'action :upgrade with tgz' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/opt/splunkforwarder/bin/splunk').and_return(true)
    end

    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz'
        action :upgrade
      end
    end

    it { is_expected.to upgrade_splunk_installer('splunkforwarder') }
    it { is_expected.to run_execute('extract splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz') }
  end

  context 'action :remove with tgz' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.tgz'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_installer('splunkforwarder') }
  end
end
