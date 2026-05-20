# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_monitor' do
  platform 'ubuntu', '24.04'

  context 'action :create with required properties' do
    recipe do
      splunk_monitor 'monitor:///var/log/syslog' do
        inputs_conf_path '/opt/splunkforwarder/etc/system/local/inputs.conf'
        index 'main'
        sourcetype 'syslog'
      end
    end

    it { is_expected.to create_splunk_monitor('monitor:///var/log/syslog') }
  end

  context 'action :create with additional options' do
    recipe do
      splunk_monitor 'monitor:///var/log/apache2' do
        inputs_conf_path '/opt/splunkforwarder/etc/system/local/inputs.conf'
        index 'web'
        sourcetype 'access_combined'
        host 'webserver01'
        recursive true
      end
    end

    it { is_expected.to create_splunk_monitor('monitor:///var/log/apache2') }
  end

  context 'action :remove' do
    recipe do
      splunk_monitor 'monitor:///var/log/syslog' do
        inputs_conf_path '/opt/splunkforwarder/etc/system/local/inputs.conf'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_monitor('monitor:///var/log/syslog') }
  end
end
