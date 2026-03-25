# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

# Install old version first
splunk_installer 'splunk' do
  url node['test']['upgrade_server_url']
end

# Then upgrade to current
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
end
