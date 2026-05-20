# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

splunk_client 'default' do
  url node['test']['forwarder_url']
  server_list 'localhost:9997'
  outputs_conf(
    'forwardedindex.0.whitelist' => '.*',
    'forwardedindex.1.blacklist' => '_.*',
    'forwardedindex.2.whitelist' => '_audit',
    'forwardedindex.filter.disable' => 'false'
  )
end

splunk_service 'splunk' do
  install_dir '/opt/splunkforwarder'
  service_name 'SplunkForwarder'
  runas_user 'splunk'
  admin_password 'notarealpassword'
end
