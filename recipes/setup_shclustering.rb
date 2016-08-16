#
# Cookbook Name:: splunk
# Recipe:: setup_shclustering
#
# Author: Ryan LeViseur <ryanlev@gmail.com>
# Copyright (c) 2014, Chef Software, Inc <legal@chef.io>
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
unless node['splunk']['shclustering']['enabled']
  Chef::Log.debug('The chef-splunk::setup_shclustering recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable search head clustering was not set.')
  return
end

# ensure that the splunk service resource is available without cloning
# the resource (CHEF-3694). this is so the later notification works,
# especially when using chefspec to run this cookbook's specs.
begin
  resources('service[splunk]')
rescue Chef::Exceptions::ResourceNotFound
  service 'splunk'
end

include_recipe 'chef-vault'

passwords = chef_vault_item('vault', "splunk_#{node.chef_environment}")
splunk_auth_info = passwords['auth']
shcluster_secret = passwords['shcluster_secret']

shcluster_params = node['splunk']['shclustering']
shcluster_servers_list = shcluster_params['shcluster_members'].join(',')

# build out the command params
splunk_cmd_params = "-mgmt_uri #{shcluster_params['mgmt_uri']}\
 -replication_factor #{shcluster_params['replication_factor']}\
 -replication_port #{shcluster_params['replication_port']}\
 -conf_deploy_fetch_url #{shcluster_params['deployer_url']}"

# add the secret if one is used
splunk_cmd_params << " -secret #{shcluster_secret}" if shcluster_secret

# execute splunk command to initialize shcluster config
execute 'init-shcluster-config' do
	command "#{splunk_cmd} init shcluster-config #{splunk_cmd_params} -auth '#{splunk_auth_info}'"
	not_if { ::File.exist?("#{splunk_dir}/etc/.setup_shcluster") }
	notifies :restart, 'service[splunk]'
end

# bootstrap the shcluster and elect a captain
execute 'bootstrap-shcluster' do
  command "#{splunk_cmd} bootstrap shcluster-captain -servers_list #{shcluster_servers_list} -auth '#{splunk_auth_info}'"
  not_if { ::File.exist?("#{splunk_dir}/etc/.setup_shcluster") }
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/.setup_shcluster" do
  content 'true\n'
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00600
end