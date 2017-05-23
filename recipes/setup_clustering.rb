#
# Cookbook:: chef-splunk
# Recipe:: setup_clustering
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
unless node['splunk']['clustering']['enabled']
  Chef::Log.debug('The chef-splunk::setup_clustering recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable clustering was not set.')
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

cluster_secret = passwords['secret']
cluster_params = node['splunk']['clustering']
cluster_mode = cluster_params['mode']
is_multisite = cluster_params['num_sites'] > 1

Chef::Log.debug("Current node clustering mode: #{cluster_mode}")

cluster_master = search(
  :node,
  "\
  splunk_clustering_enabled:true AND \
  splunk_clustering_mode:master AND \
  chef_environment:#{node.chef_environment}"
).first unless cluster_mode == 'master'

case cluster_mode
when 'master'
  splunk_cmd_params = '-mode master'
  if is_multisite
    available_sites = (1..cluster_params['num_sites']).to_a.map { |i| 'site' + i.to_s }.join(',')
    splunk_cmd_params <<
      " -multisite true -available_sites #{available_sites} -site #{cluster_params['site']}" \
      " -site_replication_factor #{cluster_params['site_replication_factor']}" \
      " -site_search_factor #{cluster_params['site_search_factor']}"
  else
    splunk_cmd_params <<
      " -replication_factor #{cluster_params['replication_factor']}" \
      " -search_factor #{cluster_params['search_factor']}"
  end
when 'slave', 'searchhead'
  splunk_cmd_params = "-mode #{cluster_mode}"
  splunk_cmd_params << " -site #{cluster_params['site']}" if is_multisite
  splunk_cmd_params <<
    " -master_uri https://#{cluster_master['ipaddress'] || cluster_master['fqdn']}:#{cluster_master['splunk']['mgmt_port']}" \
    " -replication_port #{cluster_params['replication_port']}"
else
  Chef::Log.fatal("You have set an incorrect clustering mode: #{cluster_mode}")
  Chef::Log.fatal("Set `node['splunk']['clustering']['mode']` to master|slave|searchhead, and try again.")
  raise 'Failed to setup clustering'
end

splunk_cmd_params << " -secret #{cluster_secret}" if cluster_secret

execute 'setup-indexer-cluster' do
  command "#{splunk_cmd} edit cluster-config #{splunk_cmd_params} -auth '#{splunk_auth_info}'"
  not_if { ::File.exist?("#{splunk_dir}/etc/.setup_clustering") }
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/.setup_clustering" do
  content 'true\n'
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode '600'
end
