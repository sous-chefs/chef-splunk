# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

splunk_server 'default' do
  url node['test']['server_url']
  splunk_auth 'admin:notarealpassword'
end

splunk_service 'splunk' do
  install_dir '/opt/splunk'
  service_name 'Splunkd'
  runas_user 'splunk'
end

splunk_shclustering 'default' do
  install_dir '/opt/splunk'
  mode 'deployer'
  label 'shcluster1'
  replication_factor 3
  secret 'shcluster_secret'
  runas_user 'splunk'
end
