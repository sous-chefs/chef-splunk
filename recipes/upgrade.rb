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

unless node['splunk']['upgrade_enabled']
  Chef::Log.fatal('The chef-splunk::upgrade recipe was added to the node,')
  Chef::Log.fatal('but the attribute `node["splunk"]["upgrade_enabled"]` was not set.')
  Chef::Log.fatal('I am bailing here so this node does not upgrade.')
  raise 'Failed to upgrade'
end

# ensure that the splunk service resource is available without cloning
# the resource (CHEF-3694). this is so the later notification works,
# especially when using chefspec to run this cookbook's specs.
begin
  resources('service[splunk]')
rescue Chef::Exceptions::ResourceNotFound
  service 'splunk' do
    supports status: true, restart: true
    provider splunk_service_provider
    action :nothing
  end
end

splunk_package = node['splunk']['is_server'] == true ? 'splunk' : 'splunkforwarder'
url_type = node['splunk']['is_server'] == true ? 'server' : 'forwarder'

if node['splunk']['accept_license'] != true
  Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
  Chef::Log.fatal('Splunk is stopped and cannot be restarted until the license is accepted!')
  raise 'Failed to upgrade'
end

splunk_installer "#{splunk_package} upgrade" do
  action :upgrade
  url node['splunk']['upgrade']["#{url_type}_url"]
  notifies :stop, 'service[splunk]', :before
  notifies :run, 'execute[splunk-unattended-upgrade]', :immediately
  notifies :start, 'service[splunk]'
end

execute 'splunk-unattended-upgrade' do
  action :nothing
  command "#{splunk_cmd} start --accept-license --answer-yes --no-prompt"
end
