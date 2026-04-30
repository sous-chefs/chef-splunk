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
