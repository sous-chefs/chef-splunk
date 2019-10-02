return if node['splunk']['is_server'] == true

include_recipe 'chef-splunk::install_forwarder'

begin
  resources('service[splunk]')
rescue Chef::Exceptions::ResourceNotFound
  service 'splunk' do
    action :nothing
  end
end

splunk_installer 'splunkforwarder' do
  action :remove
  notifies :stop, 'service[splunk]', :before
end
