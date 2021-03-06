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

_user, pw = node.run_state['splunk_auth_info'].split(':')

# Splunk will delete this file the first time splunk is started
# it's a secure way of automating the initial admin password when installing Splunk
# I dont believe this happens anymore. But when given a password here it re-writes the file to hold the hash of the password.
file 'user-seed.conf' do
  path "#{splunk_dir}/etc/system/local/user-seed.conf"
  content lazy {
            <<~SEED
              [user_info]
              USERNAME = admin
              HASHED_PASSWORD = #{hash_passwd(pw)}
            SEED
          }
  owner splunk_runas_user
  group splunk_runas_user
  mode '0640'
  not_if { ::File.exist?("#{splunk_dir}/etc/system/local/.user-seed.conf") || splunk_login_successful? }
end
