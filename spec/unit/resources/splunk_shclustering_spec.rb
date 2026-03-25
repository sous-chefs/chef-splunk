# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_shclustering' do
  step_into :splunk_shclustering
  platform 'ubuntu', '24.04'

  context 'action :create in deployer mode' do
    recipe do
      splunk_shclustering 'default' do
        install_dir '/opt/splunk'
        mode 'deployer'
        label 'shcluster1'
        replication_factor 3
        secret 'shcluster_secret'
        runas_user 'splunk'
      end
    end

    it { is_expected.to create_directory('/opt/splunk/etc/apps/0_PC_shcluster_config') }
    it { is_expected.to create_directory('/opt/splunk/etc/apps/0_PC_shcluster_config/local') }
    it { is_expected.to create_template('/opt/splunk/etc/apps/0_PC_shcluster_config/local/server.conf') }
  end

  context 'action :create in member mode' do
    recipe do
      splunk_shclustering 'default' do
        install_dir '/opt/splunk'
        mode 'member'
        mgmt_uri 'https://shmember1:8089'
        replication_port 34567
        replication_factor 3
        deployer_url 'https://deployer:8089'
        label 'shcluster1'
        secret 'shcluster_secret'
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_execute('initialize search head cluster member') }
  end
end
