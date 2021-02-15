# this recipe tests the `splunk_monitor` resource in Test Kitchen
directory '/var/log/httpd'

file '/var/log/httpd/access.log' do
  action :create_if_missing
end

splunk_monitor '/var/log/httpd/access.log' do
  inputs_conf_path "#{splunk_dir}/etc/apps/SplunkUniversalForwarder/default/inputs.conf"
  sourcetype 'access_combined'
  index 'access_combined'
  only_if { ::File.exist?('/var/log/httpd/access.log') }
end
