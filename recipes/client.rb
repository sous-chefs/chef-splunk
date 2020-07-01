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
include_recipe 'chef-splunk::user' if !node['splunk']['server']['runasroot']
include_recipe 'chef-splunk::install_forwarder' unless server?
include_recipe 'chef-splunk::service'

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

# if the splunk daemon is running as root, executing a normal service restart or stop will fail if the boot
# start script has been modified to execute splunk as a non-root user.
# So, the splunk daemon must be run this way instead
execute "#{splunk_cmd} stop" do
  action :nothing
  not_if { node['splunk']['server']['runasroot'] == true }
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

splunk_app 'chef_splunk_universal_forwarder' do
  files_mode '0644'
  templates ['limits.conf.erb']
  template_variables(
    'limits.conf.erb' => {
      ratelimit_kbps: node['splunk']['ratelimit_kilobytessec'],
    }
  )
  action :install
  notifies :restart, 'service[splunk]'
end

include_recipe 'chef-splunk::setup_auth' if setup_auth?
