#
# Cookbook:: chef-splunk
# Recipe:: install_server
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

splunk_installer 'splunk' do
  if upgrade_enabled?
    action :upgrade
    url node['splunk']['server']['upgrade']['url']
    notifies :run, 'ruby_block[update_default_splunk_attributes]', :immediately
  else
    url node['splunk']['server']['url']
  end
  only_if { server? }
end

ruby_block 'update_default_splunk_attributes' do
  action :nothing
  block do
    node.force_default['splunk']['server']['url'] = node['splunk']['server']['upgrade']['url']
    node.force_default['splunk']['server']['version'] = node['splunk']['server']['upgrade']['version']
    node.force_default['splunk']['upgrade_enabled'] = false
  end
end
