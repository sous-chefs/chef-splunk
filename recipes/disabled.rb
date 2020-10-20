#
# Cookbook:: chef-splunk
# Recipe:: disabled
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
return unless splunk_installed?

unless disabled?
  log 'splunk is not disabled' do
    message 'The chef-splunk::disabled recipe was added to the node, ' \
            "but node['splunk']['disabled'] was set to false."
    level :debug
  end
  return
end

include_recipe 'chef-splunk::service'

execute 'splunk disable boot-start' do
  command boot_start_cmd('disable')
  notifies :stop, 'service[splunk]', :before
end
