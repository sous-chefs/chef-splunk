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
include_recipe 'chef-splunk::setup_auth' if node['splunk']['setup_auth'] == true

# during an initial install, the start/restart commands must deal with accepting
# the license. So, we must ensure the service[splunk] resource
# properly deals with the license.
edit_resource(:service, 'splunk') do
  action node['init_package'] == 'systemd' ? %i(start enable) : :start
  supports status: true, restart: true
  stop_command svc_command('stop')
  start_command svc_command('start')
  restart_command svc_command('restart')
  provider splunk_service_provider
end

# We can rely on loading the chef_vault_item here, as `setup_auth`
# above would have failed if there were another issue.
splunk_auth_info = chef_vault_item(:vault, "splunk_#{node.chef_environment}")['auth']

execute 'update-splunk-mgmt-port' do
  command "#{splunk_cmd} set splunkd-port #{node['splunk']['mgmt_port']} -auth '#{splunk_auth_info}'"
  sensitive true
  not_if "#{splunk_cmd} show splunkd-port -auth '#{splunk_auth_info}' | grep ': #{node['splunk']['mgmt_port']}'"
  notifies :restart, 'service[splunk]'
end

execute 'enable-splunk-receiver-port' do
  command "#{splunk_cmd} enable listen #{node['splunk']['receiver_port']} -auth '#{splunk_auth_info}'"
  sensitive true
  not_if do
    # TCPSocket will return a file descriptor if it can open the connection,
    # and raise Errno::ECONNREFUSED or Errno::ETIMEDOUT if it can't. We rescue
    # that exception and return false so not_if works proper-like.
    begin
      ::TCPSocket.new(node['ipaddress'], node['splunk']['receiver_port'])
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
      false
    end
  end
end

include_recipe 'chef-splunk::setup_ssl' if node['splunk']['ssl_options']['enable_ssl']

include_recipe 'chef-splunk::setup_clustering' if node['splunk']['clustering']['enabled']

include_recipe 'chef-splunk::setup_shclustering' if node['splunk']['shclustering']['enabled']
