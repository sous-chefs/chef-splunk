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

myuser = 'root'
unless node['splunk']['server']['runasroot']
  myuser = node['splunk']['user']['username']
end

if node['splunk']['is_server']
  directory splunk_dir do
    owner myuser
    group myuser
    mode 00755
  end

  directory "#{splunk_dir}/var" do
    owner node['splunk']['user']['username']
    group node['splunk']['user']['username']
    mode 00711
  end

  directory "#{splunk_dir}/var/log" do
    owner node['splunk']['user']['username']
    group node['splunk']['user']['username']
    mode 00711
  end

  directory "#{splunk_dir}/var/log/splunk" do
    owner node['splunk']['user']['username']
    group node['splunk']['user']['username']
    mode 00700
  end
end

if node['splunk']['accept_license']
  execute "#{splunk_cmd} enable boot-start --accept-license --answer-yes" do
    only_if { File.exist?("#{splunk_dir}/ftr") }
  end
end

def chown_r_splunk(triggerfile, user)
  ruby_block 'splunk_fix_file_ownership' do
    block do
      FileUtils.chown_R(user, user, splunk_dir)
    end
    only_if { ::File.stat(triggerfile).uid.eql?(0) }
  end if node['splunk']['is_server']
end

chown_r_splunk("#{splunk_dir}/etc/users", myuser)
chown_r_splunk(splunk_dir, myuser)

template '/etc/init.d/splunk' do
  source 'splunk-init.erb'
  mode 0700
  variables(
    :splunkdir => splunk_dir,
    :runasroot => node['splunk']['server']['runasroot']
  )
end

service 'splunk' do
  supports :status => true, :restart => true
  provider Chef::Provider::Service::Init
  action :start
end
