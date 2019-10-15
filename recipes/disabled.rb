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

if node['splunk']['disabled'] == false
  log 'splunk is not disabled' do
    message 'The chef-splunk::disabled recipe was added to the node, ' \
            'but the attribute to disable splunk was not set.'
    level :debug
  end
  return
end

service 'splunk' do
  ignore_failure true
  action :stop
end

package %w(splunk splunkforwarder) do
  ignore_failure true
  action :remove
end

execute "#{splunk_cmd} disable boot-start" do
  user 'root'
  ignore_failure true
end
