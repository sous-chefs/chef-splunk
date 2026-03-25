# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

# Install old version first
splunk_installer 'splunkforwarder' do
  url node['test']['upgrade_forwarder_url']
end

# Then upgrade to current
splunk_client 'default' do
  url node['test']['forwarder_url']
  server_list 'localhost:9997'
end

splunk_service 'splunk' do
  install_dir '/opt/splunkforwarder'
  service_name 'SplunkForwarder'
  runas_user 'splunk'
end
