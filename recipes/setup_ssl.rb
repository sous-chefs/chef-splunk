#
# Cookbook Name:: splunk
# Recipe:: setup_ssl2
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
unless node['splunk']['ssl_options']['enable_ssl']
  Chef::Log.debug('The chef-splunk::setup_ssl recipe was added to the node,')
  Chef::Log.debug('but the attribute to enable SSL was not set.')
  return
end

include_recipe 'chef-vault'
ssl_options = node['splunk']['ssl_options']

certs = chef_vault_item(
  ssl_options['data_bag'],
  ssl_options['data_bag_item']
)['data']

# ensure that the splunk service resource is available without cloning
# the resource (CHEF-3694). this is so the later notification works,
# especially when using chefspec to run this cookbook's specs.
begin
  resources('service[splunk]')
rescue Chef::Exceptions::ResourceNotFound
  service 'splunk'
end

template "#{splunk_dir}/etc/system/local/web.conf" do
  source 'system-web.conf.erb'
  variables ssl_options
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/auth/splunkweb/#{ssl_options['keyfile']}" do
  content certs[ssl_options['keyfile']]
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00600
  notifies :restart, 'service[splunk]'
end

file "#{splunk_dir}/etc/auth/splunkweb/#{ssl_options['crtfile']}" do
  content certs[ssl_options['crtfile']]
  owner node['splunk']['user']['username']
  group node['splunk']['user']['username']
  mode 00600
  notifies :restart, 'service[splunk]'
end
