# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_index' do
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      splunk_index 'main' do
        indexes_conf_path '/opt/splunk/etc/system/local/indexes.conf'
        options('homePath' => '$SPLUNK_DB/main/db', 'coldPath' => '$SPLUNK_DB/main/colddb')
      end
    end

    it { is_expected.to create_splunk_index('main') }
  end

  context 'action :create with custom backup' do
    recipe do
      splunk_index 'custom' do
        indexes_conf_path '/opt/splunk/etc/system/local/indexes.conf'
        backup false
        options('maxDataSize' => 'auto_high_volume')
      end
    end

    it { is_expected.to create_splunk_index('custom') }
  end

  context 'action :remove' do
    recipe do
      splunk_index 'old_index' do
        indexes_conf_path '/opt/splunk/etc/system/local/indexes.conf'
        action :remove
      end
    end

    it { is_expected.to remove_splunk_index('old_index') }
  end
end
