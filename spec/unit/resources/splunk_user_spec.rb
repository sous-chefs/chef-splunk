# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_user' do
  step_into :splunk_user
  platform 'ubuntu', '24.04'

  context 'action :create with defaults' do
    recipe do
      splunk_user 'splunk'
    end

    it { is_expected.to create_group('splunk').with(gid: 396, system: true) }
    it { is_expected.to create_user('splunk').with(uid: 396, gid: 'splunk', shell: '/bin/bash', system: true) }
  end

  context 'action :create with custom properties' do
    recipe do
      splunk_user 'custom_splunk' do
        uid 500
        gid 500
        comment 'Custom Splunk User'
        shell '/sbin/nologin'
        home '/opt/splunk'
      end
    end

    it { is_expected.to create_group('custom_splunk').with(gid: 500, system: true) }
    it { is_expected.to create_user('custom_splunk').with(uid: 500, gid: 'custom_splunk', shell: '/sbin/nologin', home: '/opt/splunk', comment: 'Custom Splunk User', system: true) }
  end

  context 'action :remove' do
    recipe do
      splunk_user 'splunk' do
        action :remove
      end
    end

    it { is_expected.to remove_user('splunk') }
    it { is_expected.to remove_group('splunk') }
  end
end
