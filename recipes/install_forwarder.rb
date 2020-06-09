#
# Cookbook:: chef-splunk
# Recipe:: install_forwarder
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

splunk_installer 'splunkforwarder' do
  url node['splunk']['forwarder']['url']
  version node['splunk']['forwarder']['version']
  not_if { server? }
end

# The init scripts are deprecated.  Splunk
# now includes the ability to update the system boot configuration on its own.
# to run "splunk enable boot-start".  This will create an
# init script (or other configuration change) appropriate for your OS.
execute 'enable boot-start' do
  user 'root'
  command "#{splunk_cmd} enable boot-start --answer-yes --no-prompt#{license_accepted? ? ' --accept-license' : ''}#{node['init_package'] == 'systemd' ? ' -systemd-managed 1 -systemd-unit-file-name splunk.service' : ''}"
  creates node['init_package'] == 'systemd' ? '/etc/systemd/system/splunk.service' : '/etc/init.d/splunk'
end
