return if server?

include_recipe 'chef-splunk::install_forwarder'

find_resource(:service, 'splunk') do
  action :nothing
end if splunk_installed?

splunk_installer 'splunkforwarder' do
  url node['splunk']['forwarder']['url']
  version node['splunk']['forwarder']['version']
  action :remove
  notifies :stop, 'service[splunk]', :before if splunk_installed?
end
