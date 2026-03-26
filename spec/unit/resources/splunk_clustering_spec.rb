# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_clustering' do
  step_into :splunk_clustering
  platform 'ubuntu', '24.04'

  context 'action :create in master mode' do
    recipe do
      splunk_clustering 'default' do
        install_dir '/opt/splunk'
        mode 'master'
        replication_factor 3
        search_factor 2
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_execute('setup-indexer-cluster').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
    it { is_expected.to nothing_file('/opt/splunk/etc/.setup_clustering') }
  end

  context 'action :create in slave mode' do
    recipe do
      splunk_clustering 'default' do
        install_dir '/opt/splunk'
        mode 'slave'
        master_uri 'https://master:8089'
        replication_port 9887
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_execute('setup-indexer-cluster').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
  end

  context 'action :create in master mode with multisite' do
    recipe do
      splunk_clustering 'default' do
        install_dir '/opt/splunk'
        mode 'master'
        num_sites 2
        site 'site1'
        site_replication_factor 'origin:2,total:3'
        site_search_factor 'origin:1,total:2'
        splunk_auth 'admin:notarealpassword'
      end
    end

    it { is_expected.to run_execute('setup-indexer-cluster').with(environment: { 'SPLUNK_USER' => 'admin', 'SPLUNK_PASSWORD' => 'notarealpassword' }) }
  end
end
