# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_auth' do
  step_into :splunk_auth
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      splunk_auth 'admin' do
        install_dir '/opt/splunk'
        admin_password 'notarealpassword'
      end
    end

    it { is_expected.to create_directory('/opt/splunk/etc/system/local') }
    it do
      expect(chef_run).to create_file('user-seed.conf')
        .with(content: "[user_info]\nUSERNAME = admin\nPASSWORD = notarealpassword\n")
    end
  end

  context 'action :create with custom user' do
    recipe do
      splunk_auth 'custom_admin' do
        install_dir '/opt/splunk'
        admin_user 'myadmin'
        admin_password 'secretpass'
      end
    end

    it do
      expect(chef_run).to create_file('user-seed.conf')
        .with(content: "[user_info]\nUSERNAME = myadmin\nPASSWORD = secretpass\n")
    end
  end
end
