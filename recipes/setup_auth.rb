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

include_recipe 'chef-splunk'

user, pw = node.run_state['splunk_auth_info'].split(':')

file "#{splunk_dir}/etc/passwd" do
  action :nothing
end

template 'user-seed.conf' do
  path "#{splunk_dir}/etc/system/local/user-seed.conf"
  source 'user-seed-conf.erb'
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
  sensitive true unless Chef::Log.debug?
  variables user: user, hashed_password: lazy { hash_passwd(pw) }
  notifies :delete, "file[#{splunk_dir}/etc/passwd]", :immediately
  notifies :restart, 'service[splunk]', :immediately
  not_if { ::File.exist?("#{splunk_dir}/etc/system/local/.user-seed.conf") }
end

file '.user-seed.conf' do
  path "#{splunk_dir}/etc/system/local/.user-seed.conf"
  content "true\n"
  owner splunk_runas_user
  group splunk_runas_user
  mode '600'
end
