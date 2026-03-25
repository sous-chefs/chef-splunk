# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_installer' do
  platform 'ubuntu', '24.04'

  context 'action :run' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
  end

  context 'action :run with version' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        version '9.4.0'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
  end

  context 'action :upgrade' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        action :upgrade
      end
    end

    it { is_expected.to upgrade_splunk_installer('splunkforwarder') }
  end

  context 'action :remove' do
    recipe do
      splunk_installer 'splunkforwarder' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_installer('splunkforwarder') }
  end
end
