# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

splunk_server 'default' do
  url node['test']['server_url']
  splunk_auth 'admin:notarealpassword'
end

splunk_auth 'admin' do
  install_dir '/opt/splunk'
  admin_password 'notarealpassword'
end

splunk_service 'splunk' do
  install_dir '/opt/splunk'
  service_name 'Splunkd'
  runas_user 'splunk'
  admin_password 'notarealpassword'
end

splunk_app 'chef_splunk_universal_forwarder' do
  remote_directory 'chef_splunk_universal_forwarder'
  templates %w(limits.conf.erb)
  template_variables(
    'limits.conf.erb' => {
      ratelimit_kbps: 0,
    }
  )
  action :install
end

splunk_index 'test_index' do
  indexes_conf_path '/opt/splunk/etc/system/local/indexes.conf'
  options(
    'homePath' => '$SPLUNK_DB/test_index/db',
    'coldPath' => '$SPLUNK_DB/test_index/colddb',
    'thawedPath' => '$SPLUNK_DB/test_index/thaweddb'
  )
end
