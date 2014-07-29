#
# Cookbook Name:: splunk
# Recipe:: service
#
# Author: Joshua Timberman <joshua@getchef.com>
# Copyright (c) 2014, Chef Software, Inc <legal@getchef.com>
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

directory "#{splunk_dir}" do
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00755
  action :create
  not_if { ::File.exists?("#{splunk_dir}") }
  not_if { node['splunk']['server']['runasroot'] }
  only_if { node['splunk']['is_server'] }
end

directory "#{splunk_dir}/var" do
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00711
  action :create
  not_if { ::File.exists?("#{splunk_dir}/var") }
  not_if { node['splunk']['server']['runasroot'] }
  only_if { node['splunk']['is_server'] }
end

directory "#{splunk_dir}/var/log/splunk" do
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00700
  action :create
  recursive true
  not_if { ::File.exists?("#{splunk_dir}/var/log/splunk") }
  not_if { node['splunk']['server']['runasroot'] }
  only_if { node['splunk']['is_server'] }
end

if node['splunk']['accept_license']
  execute "#{splunk_cmd} enable boot-start --accept-license --answer-yes" do
    unless node['splunk']['server']['runasroot']
      command "#{splunk_cmd} enable boot-start --accept-license --answer-yes -user #{node['splunk']['user']['username']}"
      not_if 'grep -q /bin/su /etc/init.d/splunk'
      only_if { node['splunk']['is_server'] }
    end
    not_if { ::File.exist?('/etc/init.d/splunk') }
  end
end

splunk_fix_file_ownership 'splunk' do
  chownpath splunk_dir
  triggerdir "#{splunk_dir}/etc/users"
end

service 'splunk' do
  supports :status => true, :restart => true
  provider Chef::Provider::Service::Init
  action :start
end
