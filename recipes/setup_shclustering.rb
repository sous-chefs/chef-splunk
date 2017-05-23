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
shcluster_secret = passwords['secret']
shcluster_params = node['splunk']['shclustering']

# create app directories to house our server.conf with our shcluster configuration
shcluster_app_dir = "#{splunk_dir}/etc/apps/0_autogen_shcluster_config"

directory shcluster_app_dir do
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 0755
end

directory "#{shcluster_app_dir}/local" do
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 0755
end

template "#{shcluster_app_dir}/local/server.conf" do # ~FC033
  source 'shclustering/server.conf.erb'
  mode 0600
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  variables(
    shcluster_params: node['splunk']['shclustering'],
    shcluster_secret: shcluster_secret
  )
  sensitive true
  notifies :restart, 'service[splunk]', :immediately
end

# bootstrap the shcluster and elect a captain if initial_captain set to true and this is the initial shcluster build
if node['splunk']['shclustering']['mode'] == 'captain'
  # unless shcluster members are staticly assigned via the node attribute,
  # try to find the other shcluster members via Chef search
  if shcluster_params['shcluster_members'].empty?
    shcluster_servers_list = []
    search( # ~FC003
      :node,
      "\
      splunk_shclustering_enabled:true AND \
      splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
      chef_environment:#{node.chef_environment}"
    ).each do |result|
      shcluster_servers_list << result['splunk']['shclustering']['mgmt_uri']
    end
  else
    shcluster_servers_list = shcluster_params['shcluster_members']
  end

  execute 'bootstrap-shcluster' do
    command "#{splunk_cmd} bootstrap shcluster-captain -servers_list '#{shcluster_servers_list.join(',')}' -auth '#{splunk_auth_info}'"
    not_if { ::File.exist?("#{splunk_dir}/etc/.setup_shcluster") }
    notifies :restart, 'service[splunk]'
  end
end

file "#{splunk_dir}/etc/.setup_shcluster" do
  content 'true\n'
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00600
end
