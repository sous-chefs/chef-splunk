#
# Cookbook:: chef-splunk
# Recipe:: default
#
# Author: Dang H. Nguyen <dang.nguyen@disney.com>
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
if disabled?
  include_recipe 'chef-splunk::disabled'
  Chef::Log.debug('Splunk is disabled on this node.')
  return
end

# We can rely on loading the chef_vault_item here into the run_state so other
# recipes don't have to keep going back to the chef server to access the vault/data bag item
vault_item = chef_vault_item(node['splunk']['data_bag'], "splunk_#{node.chef_environment}")
node.run_state['splunk_auth_info'] = splunk_auth(vault_item['auth'])
node.run_state['splunk_secret'] = vault_item['secret']

if server?
  include_recipe 'chef-splunk::server'
else
  include_recipe 'chef-splunk::client'
end
