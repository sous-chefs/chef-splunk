#
# Cookbook:: chef-splunk
# Recipe:: server
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
node.default['splunk']['is_server'] = true
include_recipe 'chef-splunk::user'
include_recipe 'chef-splunk::install_server'
include_recipe 'chef-splunk::service'
include_recipe 'chef-splunk::setup_auth'

# ensure that the splunk service resource is available without cloning
# the resource (CHEF-3694). this is so the later notification works,
# especially when using chefspec to run this cookbook's specs.
begin
  resources('service[splunk]')
rescue Chef::Exceptions::ResourceNotFound
  service 'splunk'
end

# We can rely on loading the chef_vault_item here, as `setup_auth`
# above would have failed if there were another issue.
splunk_auth_info = chef_vault_item(:vault, "splunk_#{node.chef_environment}")['auth']

execute 'update-splunk-mgmt-port' do
  command "#{splunk_cmd} set splunkd-port #{node['splunk']['mgmt_port']} -auth '#{splunk_auth_info}'"
  not_if "#{splunk_cmd} show splunkd-port -auth '#{splunk_auth_info}' | grep ': #{node['splunk']['mgmt_port']}'"
  notifies :restart, 'service[splunk]'
end

execute 'enable-splunk-receiver-port' do
  command "#{splunk_cmd} enable listen #{node['splunk']['receiver_port']} -auth '#{splunk_auth_info}'"
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

if node['splunk']['ssl_options']['enable_ssl']
  include_recipe 'chef-splunk::setup_ssl'
end

if node['splunk']['clustering']['enabled']
  include_recipe 'chef-splunk::setup_clustering'
end

if node['splunk']['shclustering']['enabled']
  include_recipe 'chef-splunk::setup_shclustering'
end
