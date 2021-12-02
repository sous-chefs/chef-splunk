return if server?

include_recipe 'chef-splunk::install_forwarder' unless ::File.exist?('/tmp/.uf_installed_once')

file '/tmp/.uf_installed_once' do
  action :touch
  only_if { splunk_installed? }
end

# this ruby_block is necessary to effectively mitigate notifications sent from other
# resources to the service[splunk] service and the execute[/opt/splunkforwarder/bin/splunk stop]
edit_resource(:service, 'splunk') do
  restart_command('/bin/true')
  start_command('/bin/true')
end

splunk_installer 'splunkforwarder' do
  url node['splunk']['forwarder']['url']
  version node['splunk']['forwarder']['version']
  action :remove
end
