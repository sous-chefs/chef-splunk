#
# Cookbook:: chef-splunk
# Recipe:: server
#
# Copyright:: 2014-2019, Chef Software, Inc.
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
node.default['splunk']['is_server'] = true

include_recipe 'chef-splunk::user'
include_recipe 'chef-splunk::install_server'
include_recipe 'chef-splunk::service'
include_recipe 'chef-splunk::setup_auth' if setup_auth?

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

execute 'update-splunk-mgmt-port' do
  command "#{splunk_cmd} set splunkd-port #{node['splunk']['mgmt_port']} -auth '#{node.run_state['splunk_auth_info']}'"
  sensitive true unless Chef::Log.debug?
  not_if { current_mgmt_port == node['splunk']['mgmt_port'] }
  notifies :restart, 'service[splunk]'
end

ruby_block 'enable-splunk-receiver-port' do
  sensitive true unless Chef::Log.debug?
  block do
    splunk = Mixlib::ShellOut.new("#{splunk_cmd} enable listen #{node['splunk']['receiver_port']} -auth #{node.run_state['splunk_auth_info']}")
    splunk.run_command
    true if splunk.stderr.include?("Configuration for port #{node['splunk']['receiver_port']} already exists")
  end
  not_if { port_open?(node['splunk']['receiver_port']) }
  notifies :restart, 'service[splunk]'
end

include_recipe 'chef-splunk::setup_ssl' if enable_ssl?

include_recipe 'chef-splunk::setup_clustering' if enable_clustering?

include_recipe 'chef-splunk::setup_shclustering' if enable_shclustering?
