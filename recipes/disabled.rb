#
# Cookbook Name:: splunk
# Recipe:: disabled
#
# Author: Joshua Timberman <joshua@chef.io>
# Copyright (c) 2014, Chef Software, Inc <legal@chef.io>
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

unless node['splunk']['disabled']
  Chef::Log.debug('The chef-splunk::disabled recipe was added to the node,')
  Chef::Log.debug('but the attribute to disable splunk was not set.')
  return
end

service 'splunk' do
  ignore_failure true
  action :stop
end

%w(splunk splunkforwarder).each do |pkg|
  package pkg do
    ignore_failure true
    action :remove
  end
end

execute "#{splunk_dir}/bin/splunk disable boot-start" do
  ignore_failure true
end
