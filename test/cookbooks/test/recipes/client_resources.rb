# frozen_string_literal: true

apt_update 'update' if platform_family?('debian')

splunk_user 'splunk'

splunk_client 'default' do
  url node['test']['forwarder_url']
  server_list 'localhost:9997'
end

splunk_service 'splunk' do
  install_dir '/opt/splunkforwarder'
  service_name 'SplunkForwarder'
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

splunk_monitor '/var/log' do
  inputs_conf_path '/opt/splunkforwarder/etc/system/local/inputs.conf'
  index 'default'
  sourcetype 'syslog'
end
