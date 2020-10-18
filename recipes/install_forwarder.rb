#
# Cookbook:: chef-splunk
# Recipe:: install_forwarder
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
include_recipe 'chef-splunk::user'

node.default['splunk']['service_name'] = 'SplunkForwarder' if systemd?
node.default['splunk']['startup_script'] = '/etc/systemd/system/SplunkForwarder.service' if systemd?

splunk_installer 'splunkforwarder' do
  if upgrade_enabled?
    action :upgrade
    url node['splunk']['forwarder']['upgrade']['url']
    version node['splunk']['forwarder']['upgrade']['version']
    notifies :run, 'ruby_block[update_default_splunk_attributes]', :immediately
  else
    url node['splunk']['forwarder']['url']
    version node['splunk']['forwarder']['version']
  end
  not_if { server? }
end

ruby_block 'update_default_splunk_attributes' do
  action :nothing
  block do
    node.default['splunk']['forwarder']['url'] = node['splunk']['forwarder']['upgrade']['url']
    node.default['splunk']['forwarder']['version'] = node['splunk']['forwarder']['upgrade']['version']
    node.default['splunk']['upgrade_enabled'] = false
  end
end

include_recipe 'chef-splunk::service'
