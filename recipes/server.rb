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
unless license_accepted?
  Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
  raise 'Splunk license was not accepted'
end

node.default['splunk']['is_server'] = true

include_recipe 'chef-splunk::user' unless run_as_root?
include_recipe 'chef-splunk::install_server'
include_recipe 'chef-splunk::service'
include_recipe 'chef-splunk::setup_auth' if setup_auth?

execute 'update-splunk-mgmt-port' do
  command splunk_cmd("set splunkd-port #{node['splunk']['mgmt_port']} -auth '#{node.run_state['splunk_auth_info']}' --accept-license")
  sensitive true unless Chef::Log.debug?
  not_if { current_mgmt_port == node['splunk']['mgmt_port'] }
  notifies :restart, 'service[splunk]' unless disabled?
end

ruby_block 'enable-splunk-receiver-port' do
  sensitive true unless Chef::Log.debug?
  block do
    splunk = Mixlib::ShellOut.new(splunk_cmd("enable listen #{node['splunk']['receiver_port']} -auth #{node.run_state['splunk_auth_info']} --accept-license"))
    splunk.run_command
    true if splunk.stderr.include?("Configuration for port #{node['splunk']['receiver_port']} already exists")
  end
  not_if { port_open?(node['splunk']['receiver_port']) }
  notifies :restart, 'service[splunk]' unless disabled?
end

include_recipe 'chef-splunk::setup_ssl' if enable_ssl?

include_recipe 'chef-splunk::setup_clustering' if enable_clustering?

include_recipe 'chef-splunk::setup_shclustering' if enable_shclustering?
