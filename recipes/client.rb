#
# Cookbook:: chef-splunk
# Recipe:: client
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
# This recipe encapsulates a completely configured "client" - a
# Universal Forwarder configured to talk to a node that is the splunk
# server (with node['splunk']['is_server'] true). The recipes can be
# used on their own composed in your own wrapper cookbook or role.
include_recipe 'chef-splunk::user'
include_recipe 'chef-splunk::install_forwarder' unless server?

splunk_servers = search(
  :node,
  "splunk_is_server:true AND chef_environment:#{node.chef_environment}"
).sort! do |a, b|
  a.name <=> b.name
end

server_list = if !(node['splunk']['server_list'].nil? || node['splunk']['server_list'].empty?)
                # fallback to statically defined server list as alternative to search
                node['splunk']['server_list']
              else
                splunk_servers.map do |s|
                  "#{s['fqdn'] || s['ipaddress']}:#{s['splunk']['receiver_port']}"
                end.join(', ')
              end

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

directory "#{splunk_dir}/etc/system/local" do
  recursive true
  owner splunk_runas_user
  group splunk_runas_user
end

template "#{splunk_dir}/etc/system/local/outputs.conf" do
  source 'outputs.conf.erb'
  mode '644'
  variables(
    server_list: server_list,
    outputs_conf: node['splunk']['outputs_conf']
  )
  notifies :restart, 'service[splunk]'
  owner splunk_runas_user
  group splunk_runas_user
end

template "#{splunk_dir}/etc/system/local/inputs.conf" do
  source 'inputs.conf.erb'
  owner splunk_runas_user
  group splunk_runas_user
  mode '644'
  variables inputs_conf: node['splunk']['inputs_conf']
  notifies :restart, 'service[splunk]'
  not_if { node['splunk']['inputs_conf'].nil? || node['splunk']['inputs_conf']['host'].empty? }
end

template "#{splunk_dir}/etc/apps/SplunkUniversalForwarder/default/limits.conf" do
  source 'limits.conf.erb'
  owner splunk_runas_user
  group splunk_runas_user
  mode '644'
  variables ratelimit_kbps: node['splunk']['ratelimit_kilobytessec']
  notifies :restart, 'service[splunk]'
end

include_recipe 'chef-splunk::service'
include_recipe 'chef-splunk::setup_auth' if node['splunk']['setup_auth']
