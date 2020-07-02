return if server?

include_recipe 'chef-splunk::install_forwarder'

# this ruby_block is necessary to effectively mitigate notifications sent from other
# resources to the service[splunk] service and the execute[/opt/splunkforwarder/bin/splunk stop]
ruby_block 'mitigation splunk service notifications' do
  block do
    r = resources('service[splunk]')
    r.restart_command('/bin/true')
    r.stop_command('/bin/true')
    r.start_command('/bin/true')
    r.status_command('/bin/true')

    r = resources('execute[/opt/splunkforwarder/bin/splunk stop]')
    r.command('/bin/true')
  end
end

splunk_installer 'splunkforwarder' do
  url node['splunk']['forwarder']['url']
  version node['splunk']['forwarder']['version']
  action :remove
  notifies :stop, 'service[splunk]', :before if splunk_installed?
end
