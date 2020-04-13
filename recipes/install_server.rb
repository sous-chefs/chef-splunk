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
  url node['splunk']['server']['url']
  version node['splunk']['server']['version']
  only_if { server? }
end

# The init scripts are deprecated.  Splunk
# now includes the ability to update the system boot configuration on its own.
# to run "splunk enable boot-start".  This will create an
# init script (or other configuration change) appropriate for your OS.
execute 'enable boot-start' do
  user 'root'
  command enable_boot_start_cmd
  creates '/etc/init.d/splunk'
end
