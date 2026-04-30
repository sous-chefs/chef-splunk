# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_ssl' do
  step_into :splunk_ssl
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      splunk_ssl 'default' do
        install_dir '/opt/splunk'
        keyfile_content 'fake-key-content'
        crtfile_content 'fake-cert-content'
      end
    end

    it { is_expected.to create_directory('/opt/splunk/etc/auth/certs') }
    it { is_expected.to create_file('/opt/splunk/etc/auth/certs/splunk.key').with(sensitive: true) }
    it { is_expected.to create_file('/opt/splunk/etc/auth/certs/splunk.crt') }
    it { is_expected.to create_template('/opt/splunk/etc/system/local/web.conf') }
  end

  context 'action :create with custom cert paths' do
    recipe do
      splunk_ssl 'custom' do
        install_dir '/opt/splunk'
        keyfile_path '/opt/splunk/etc/auth/custom.key'
        crtfile_path '/opt/splunk/etc/auth/custom.crt'
        keyfile_content 'custom-key'
        crtfile_content 'custom-cert'
      end
    end

    it { is_expected.to create_file('/opt/splunk/etc/auth/custom.key').with(sensitive: true) }
    it { is_expected.to create_file('/opt/splunk/etc/auth/custom.crt') }
  end

  context 'action :remove' do
    recipe do
      splunk_ssl 'default' do
        install_dir '/opt/splunk'
        keyfile_content 'fake'
        crtfile_content 'fake'
        action :remove
      end
    end

    it { is_expected.to delete_file('/opt/splunk/etc/auth/certs/splunk.key') }
    it { is_expected.to delete_file('/opt/splunk/etc/auth/certs/splunk.crt') }
    it { is_expected.to delete_file('/opt/splunk/etc/system/local/web.conf') }
  end
end
