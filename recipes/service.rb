#
# Cookbook Name:: splunk
# Recipe:: service
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
  # ftr = first time run file created by a splunk install
  execute "#{splunk_cmd} enable boot-start --accept-license --answer-yes" do
    only_if { File.exist? "#{splunk_dir}/ftr" }
  end
end

# If we run as splunk user do a recursive chown to that user for all splunk
# files if a few specific files are root owned.
ruby_block 'splunk_fix_file_ownership' do
  block do
    checkowner = []
    checkowner << "#{splunk_dir}/etc/users"
    checkowner << "#{splunk_dir}/etc/myinstall/splunkd.xml"
    checkowner << "#{splunk_dir}/"
    checkowner.each do |dir|
      next unless File.exist? dir
      if File.stat(dir).uid.eql?(0)
        FileUtils.chown_R(myuser, myuser, splunk_dir)
      end
    end
  end
  not_if { node['splunk']['server']['runasroot'] }
end

template '/etc/init.d/splunk' do
  source 'splunk-init.erb'
  mode 0700
  variables(
    splunkdir: splunk_dir,
    runasroot: node['splunk']['server']['runasroot']
  )
end

service 'splunk' do
  supports status: true, restart: true
  provider Chef::Provider::Service::Init
  action :start
end
