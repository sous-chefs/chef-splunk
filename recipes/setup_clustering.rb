#
# Cookbook:: chef-splunk
# Recipe:: setup_clustering
#
# Copyright:: 2014-2020, Chef Software, Inc.
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
unless enable_clustering?
  Chef::Log.debug('The chef-splunk::setup_clustering recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable clustering was not set.')
  return
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
  status_command svc_command('status')
  provider splunk_service_provider
end

Chef::Log.debug("Current node clustering mode: #{node['splunk']['clustering']['mode']}")

unless cluster_master?
  search(
    :node,
    "\
    splunk_clustering_enabled:true AND \
    splunk_clustering_mode:master AND \
    chef_environment:#{node.chef_environment}",
    filter_result: {
      'cluster_master_mgmt_uri' => %w(splunk clustering mgmt_uri),
    }
  ).each do |result|
    node.default['splunk']['clustering']['mgmt_uri'] = result['cluster_master_mgmt_uri']
  end
end

case node['splunk']['clustering']['mode']
when 'master'
  splunk_cmd_params = '-mode master'
  if multisite_clustering?
    available_sites = (1..node['splunk']['clustering']['num_sites']).to_a.map { |i| 'site' + i.to_s }.join(',')
    splunk_cmd_params <<
      " -multisite true -available_sites #{available_sites} -site #{node['splunk']['clustering']['site']}" \
      " -site_replication_factor #{node['splunk']['clustering']['site_replication_factor']}" \
      " -site_search_factor #{node['splunk']['clustering']['site_search_factor']}"
  else
    splunk_cmd_params <<
      " -replication_factor #{node['splunk']['clustering']['replication_factor']}" \
      " -search_factor #{node['splunk']['clustering']['search_factor']}"
  end
when 'slave', 'searchhead'
  splunk_cmd_params = "-mode #{node['splunk']['clustering']['mode']}"
  splunk_cmd_params << " -site #{node['splunk']['clustering']['site']}" if multisite_clustering?
  splunk_cmd_params <<
    " -master_uri #{node.default['splunk']['clustering']['mgmt_uri']}" \
    " -replication_port #{node['splunk']['clustering']['replication_port']}"
else
  Chef::Log.error("You have set an incorrect clustering mode: #{node['splunk']['clustering']['mode']}")
  Chef::Log.error("Set `node['splunk']['clustering']['mode']` to master|slave|searchhead, and try again.")
  raise 'Failed to setup clustering: invalid clustering mode'
end

splunk_cmd_params << " -secret #{node.run_state['splunk_secret']}" if node.run_state['splunk_secret']

execute 'setup-indexer-cluster' do
  command "#{splunk_cmd} edit cluster-config #{splunk_cmd_params} -auth '#{node.run_state['splunk_auth_info']}'"
  sensitive true unless Chef::Log.debug?
  not_if { ::File.exist?("#{splunk_dir}/etc/.setup_clustering") }
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/.setup_clustering" do
  content "true\n"
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
end
