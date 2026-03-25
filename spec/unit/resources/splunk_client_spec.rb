# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_client' do
  step_into :splunk_client
  platform 'ubuntu', '24.04'

  context 'action :install with defaults' do
    recipe do
      splunk_client 'default' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        server_list 'splunkserver1:9997, splunkserver2:9997'
      end
    end

    it { is_expected.to run_splunk_installer('splunkforwarder') }
    it { is_expected.to create_directory('/opt/splunkforwarder/etc/system/local') }
    it { is_expected.to create_template('/opt/splunkforwarder/etc/system/local/outputs.conf') }
  end

  context 'action :install with custom properties' do
    recipe do
      splunk_client 'custom' do
        install_dir '/opt/splunkforwarder'
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        server_list 'splunkserver1:9997'
        receiver_port 9998
        runas_user 'root'
        outputs_conf('forceTimebasedAutoLB' => 'true')
      end
    end

    it { is_expected.to create_template('/opt/splunkforwarder/etc/system/local/outputs.conf') }
  end

  context 'action :remove' do
    recipe do
      splunk_client 'default' do
        url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-linux-2.6-amd64.deb'
        server_list 'splunkserver1:9997'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_installer('splunkforwarder') }
  end
end
