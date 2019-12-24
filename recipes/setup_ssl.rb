#
# Cookbook:: chef-splunk
# Recipe:: setup_ssl2
#
# Copyright:: 2014-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
unless node['splunk']['ssl_options']['enable_ssl']
  Chef::Log.debug('The chef-splunk::setup_ssl recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable SSL was not set.')
  return
end

ssl_options = node['splunk']['ssl_options']

certs = chef_vault_item(
  ssl_options['data_bag'],
  ssl_options['data_bag_item']
)['data']

# during an initial install, the start/restart commands must deal with accepting
# the license. So, we must ensure the service[splunk] resource
# properly deals with the license.
edit_resource(:service, 'splunk') do
  action node['init_package'] == 'systemd' ? %i(start enable) : :start
  supports status: true, restart: true
  stop_command svc_command('stop')
  start_command svc_command('start')
  restart_command svc_command('restart')
  status_command svc_command('status')
  provider splunk_service_provider
end

template "#{splunk_dir}/etc/system/local/web.conf" do
  source 'system-web.conf.erb'
  variables ssl_options
  owner splunk_runas_user
  group splunk_runas_user
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/auth/splunkweb/#{ssl_options['keyfile']}" do
  content certs[ssl_options['keyfile']]
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
  sensitive true
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/auth/splunkweb/#{ssl_options['crtfile']}" do
  content certs[ssl_options['crtfile']]
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
  sensitive true
  notifies :restart, 'service[splunk]'
end
