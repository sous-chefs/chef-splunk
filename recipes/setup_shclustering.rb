#
# Cookbook:: splunk
# Recipe:: setup_shclustering
#
# Author: Ryan LeViseur <ryanlev@gmail.com>
# Contributor: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: (c) 2014-2020, Chef Software, Inc <legal@chef.io>
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
unless enable_shclustering?
  Chef::Log.debug('The chef-splunk::setup_shclustering recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable search head clustering was not set.')
  return
end

# during an initial install, the start/restart commands must deal with accepting
# the license. So, we must ensure the service[splunk] resource
# properly deals with the license; hence, the use of `#svc_command` method calls here.
edit_resource(:service, 'splunk') do
  action node['init_package'] == 'systemd' ? %i(start enable) : :start
  supports status: true, restart: true
  stop_command svc_command('stop')
  start_command svc_command('start')
  restart_command svc_command('restart')
  status_command svc_command('status')
  provider splunk_service_provider
end

# initialize
# create app directories to house our server.conf with our shcluster configuration
directory node['splunk']['shclustering']['app_dir'] do
  owner splunk_runas_user
  group splunk_runas_user
  mode '755'
  only_if { node['splunk']['shclustering']['mode'] == 'deployer' }
end

directory "#{node['splunk']['shclustering']['app_dir']}/local" do
  owner splunk_runas_user
  group splunk_runas_user
  mode '755'
  only_if { node['splunk']['shclustering']['mode'] == 'deployer' }
end

# use the internal ec2 hostname for splunk-to-splunk communications
# this type traffic is usually free in AWS
node.force_default['splunk']['shclustering']['mgmt_uri'] = "https://#{node['ec2']['local_hostname']}:8089" if node.attribute?('ec2')

if node['splunk']['shclustering']['mode'] == 'deployer'
  template "#{node['splunk']['shclustering']['app_dir']}/local/server.conf" do
    source 'shclustering/server.conf.erb'
    mode '600'
    owner splunk_runas_user
    group splunk_runas_user
    variables(
      shcluster_params: node['splunk']['shclustering'],
      shcluster_secret: node.run_state['splunk_secret']
    )
    sensitive true
    notifies :restart, 'service[splunk]', :immediately
  end
end

# quit early for deployers or when a search head member/captain have already been provisioned
return if node['splunk']['shclustering']['mode'] == 'deployer'

#
# everything from this point on deal only with search head cluster members and the captain
#

# search for the fqdn of the search head deployer and set that as the deployer_url
# if one is not given in the node attributes
if node['splunk']['shclustering']['deployer_url'].empty?
  search(
    :node,
    "\
    splunk_shclustering_enabled:true AND \
    splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
    splunk_shclustering_mode:deployer AND \
    chef_environment:#{node.chef_environment}",
    filter_result: { 'deployer_mgmt_uri' => %w(splunk shclustering mgmt_uri) }
  ).each do |result|
    node.default['splunk']['shclustering']['deployer_url'] = result['deployer_mgmt_uri']
  end
end

# Primary rule: all captains are members; all members must be initialized before being added to a
# cluster.
#
# Secondary rule: if a captain has been setup and converged, the chef server will have its node data
# saved and search will return a proper value for the captain. If the captain has not
# converged, then a shcluster member should only initialize itself and wait until future
# chef runs to add itself as a member.

# search head cluster member list needed to bootstrap the shcluster captain
shcluster_servers_list = [node['splunk']['shclustering']['mgmt_uri']]

# unless shcluster members are staticly assigned via the node attribute,
# try to find the other shcluster members via Chef search
# if node['splunk']['shclustering']['mode'] == 'captain' &&
if node['splunk']['shclustering']['shcluster_members'].empty?
  search(
    :node,
    "\
    splunk_shclustering_enabled:true AND \
    splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
    splunk_shclustering_mode:member AND \
    chef_environment:#{node.chef_environment}",
    filter_result: { 'member_mgmt_uri' => %w(splunk shclustering mgmt_uri) }
  ).each do |result|
    shcluster_servers_list << result['member_mgmt_uri']
  end
else
  shcluster_servers_list = node['splunk']['shclustering']['shcluster_members']
end

if shcluster_servers_list.size < 3
  log 'A minimum of three search head cluster members are required for distributed search. Nothing to do this time.' do
    level :warn
  end
  return
end

# initialize the member and then quit until the next chef run;
# this effectively waits until the captain is ready before adding members to the cluster
execute 'initialize search head cluster member' do
  sensitive true
  command "#{splunk_cmd} init shcluster-config -auth '#{node.run_state['splunk_auth_info']}' " \
    "-mgmt_uri #{node['splunk']['shclustering']['mgmt_uri']} " \
    "-replication_port #{node['splunk']['shclustering']['replication_port']} " \
    "-replication_factor #{node['splunk']['shclustering']['replication_factor']} " \
    "-conf_deploy_fetch_url #{node['splunk']['shclustering']['deployer_url']} " \
    "-secret #{node.run_state['splunk_secret']} " \
    "-shcluster_label #{node['splunk']['shclustering']['label']}"
  notifies :restart, 'service[splunk]', :immediately
  only_if { init_shcluster_member? }
end

if shcluster_servers_list.size >= 2 && node['splunk']['shclustering']['mode'] == 'captain'
  execute 'bootstrap-shcluster-captain' do
    sensitive true
    command "#{splunk_cmd} bootstrap shcluster-captain -auth '#{node.run_state['splunk_auth_info']}' " \
      "-servers_list \"#{shcluster_servers_list.join(',')}\""
    notifies :restart, 'service[splunk]', :immediately
    not_if { shcaptain_elected? }
  end
elsif shcaptain_elected? && !shcluster_members_ipv4.include?(node['ipaddress'])
  captain_mgmt_uri = nil
  search(
    :node,
    "\
    splunk_shclustering_enabled:true AND \
    splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
    splunk_shclustering_mode:captain AND \
    chef_environment:#{node.chef_environment}",
    filter_result: { 'captain_mgmt_uri' => %w(splunk shclustering mgmt_uri) }
  ).each { |result| captain_mgmt_uri = result['captain_mgmt_uri'] }

  execute 'add member to search head cluster' do
    sensitive true
    command "#{splunk_cmd} add shcluster-member -current_member_uri #{captain_mgmt_uri} -auth '#{node.run_state['splunk_auth_info']}'"
    only_if { node['splunk']['shclustering']['mode'] == 'member' }
    notifies :restart, 'service[splunk]'
  end
end

cluster_master = { 'mgmt_uri' => nil, 'num_sites' => 1, 'site' => nil }
search(
  :node,
  "\
  splunk_clustering_enabled:true AND \
  splunk_clustering_mode:master AND \
  chef_environment:#{node.chef_environment}",
  filter_result: {
    'cluster_master_mgmt_uri' => %w(splunk shclustering mgmt_uri),
    'cluster_master_site' => %w(splunk clustering site),
    'cluster_num_sites' => %w(splunk clustering num_sites),
  }
).each do |result|
  cluster_master['mgmt_uri'] = result['cluster_master_mgmt_uri']
  cluster_master['site'] = result['cluster_master_site']
  cluster_master['num_sites'] = result['cluster_num_sites']
end

shpeer_integration_command = "#{splunk_cmd} edit cluster-config -mode searchhead -master_uri #{cluster_master['mgmt_uri']} " \
                             "-secret #{node.run_state['splunk_secret']} -auth #{node.run_state['splunk_auth_info']}"
shpeer_integration_command += ' -site site0' if cluster_master['num_sites'] > 1

execute 'search head cluster integration with indexer cluster' do
  sensitive true
  command shpeer_integration_command
  notifies :restart, 'service[splunk]'
  not_if { search_heads_peered? }
end
