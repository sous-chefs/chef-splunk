#
# Cookbook:: chef-splunk
# Recipe:: upgrade
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
if node['splunk'].attribute?('upgrade') && node['splunk']['upgrade'].attribute?('server_url')
  msg = "DEPRECATED: node['splunk']['upgrade']['server_url'] was found. This attribute will be removed in a future version. " \
        "Please use node['splunk']['server']['upgrade']['url'] instead"
  log msg do
    level :warn
  end
end

if node['splunk'].attribute?('upgrade') && node['splunk']['upgrade'].attribute?('forwarder_url')
  msg = "DEPRECATED: node['splunk']['upgrade']['forwarder_url'] was found. This attribute will be removed in a future version. " \
        "Please use node['splunk']['forwarder']['upgrade']['url'] instead"
  log msg do
    level :warn
  end
end

include_recipe "chef-splunk::install_#{server? ? 'server' : 'forwarder'}"
