#
# Cookbook:: chef-splunk
# Recipe:: setup_auth
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
unless setup_auth?
  log 'setup_auth is disabled' do
    message 'The chef-splunk::setup_auth recipe was added to the node, ' \
            'but the attribute to setup splunk authentication was disabled.'
    level :debug
  end
  return
end

splunk_auth_info = chef_vault_item(node['splunk']['data_bag'], "splunk_#{node.chef_environment}")['auth']
user, pw = splunk_auth_info.split(':')

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

template 'user-seed.conf' do
  path "#{splunk_dir}/etc/system/local/user-seed.conf"
  source 'user-seed-conf.erb'
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
  sensitive true
  variables user: user, password: pw
  notifies :restart, 'service[splunk]', :immediately
  not_if { File.exist?("#{splunk_dir}/etc/system/local/.user-seed.conf") }
end

file '.user-seed.conf' do
  path "#{splunk_dir}/etc/system/local/.user-seed.conf"
  content "true\n"
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
end
