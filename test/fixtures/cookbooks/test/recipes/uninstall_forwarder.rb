return if node['splunk']['is_server'] == true

include_recipe 'chef-splunk::install_forwarder'

find_resource(:service, 'splunk') do
  action :nothing
end

splunk_installer 'splunkforwarder' do
  action :remove
  notifies :stop, 'service[splunk]', :before
end
