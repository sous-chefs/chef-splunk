#
# Cookbook:: chef-splunk
# Recipe:: upgrade
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

unless node['splunk']['upgrade_enabled']
  Chef::Log.fatal('The chef-splunk::upgrade recipe was added to the node,')
  Chef::Log.fatal('but the attribute `node["splunk"]["upgrade_enabled"]` was not set.')
  Chef::Log.fatal('I am bailing here so this node does not upgrade.')
  raise 'Failed to upgrade'
end

service 'splunk_stop' do
  service_name 'splunk'
  supports status: true
  provider Chef::Provider::Service::Init
  action :stop
end

if node['splunk']['is_server']
  splunk_package = 'splunk'
  url_type = 'server'
else
  splunk_package = 'splunkforwarder'
  url_type = 'forwarder'
end

splunk_installer splunk_package do
  url node['splunk']['upgrade']["#{url_type}_url"]
end

if node['splunk']['accept_license']
  execute 'splunk-unattended-upgrade' do
    command "#{splunk_cmd} start --accept-license --answer-yes"
  end
else
  Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
  Chef::Log.fatal('Splunk is stopped and cannot be restarted until the license is accepted!')
  raise 'Failed to upgrade'
end
