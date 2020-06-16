#
# Cookbook:: chef-splunk
# Recipe:: service
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
unless license_accepted?
  Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
  raise 'Splunk license was not accepted'
end

if server?
  directory splunk_dir do
    owner splunk_runas_user
    group splunk_runas_user
    mode '755'
  end

  directory "#{splunk_dir}/var" do
    owner splunk_runas_user
    group splunk_runas_user
    mode '711'
  end

  directory "#{splunk_dir}/var/log" do
    owner splunk_runas_user
    group splunk_runas_user
    mode '711'
  end

  directory "#{splunk_dir}/var/log/splunk" do
    owner splunk_runas_user
    group splunk_runas_user
    mode '700'
  end
end

# If we run as splunk user do a recursive chown to that user for all splunk
# files if a few specific files are root owned.
ruby_block 'splunk_fix_file_ownership' do
  block do
    begin
      FileUtils.chown_R(splunk_runas_user, splunk_runas_user, splunk_dir)
    rescue Errno::ENOENT => e
      Chef::Log.warn "Possible transient file encountered in Splunk while setting ownership:\n#{e.message}"
    end
  end
  subscribes :run, 'service[splunk]', :before
  not_if { node['splunk']['server']['runasroot'] == true }
end

Chef::Log.info("Node init package: #{node['init_package']}")

template '/etc/systemd/system/splunk.service' do
  source 'splunk-systemd.erb'
  mode '644'
  variables(
    splunkdir: splunk_dir,
    splunkcmd: splunk_cmd,
    runasroot: false,
    accept_license: license_accepted?
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  only_if { node['init_package'] == 'systemd' }
end

file '/etc/systemd/system/splunkd.service' do
  action :delete
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

file '/etc/init.d/splunk' do
  action :delete
  only_if { node['init_package'] == 'systemd' }
end

execute 'systemctl daemon-reload' do
  action :nothing
  only_if { node['init_package'] == 'systemd' }
end

file '/etc/systemd/system/splunk.service' do
  action :delete
  not_if { node['init_package'] == 'systemd' }
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
end

template '/etc/init.d/splunk' do
  source 'splunk-init.erb'
  mode '700'
  variables(
    splunkdir: splunk_dir,
    splunkuser: splunk_runas_user,
    splunkcmd: splunk_cmd,
    runasroot: false,
    accept_license: license_accepted?
  )
  not_if { node['init_package'] == 'systemd' }
  notifies :run, "execute[#{splunk_cmd} stop]", :immediately # must use this if splunk daemon is running as root and needs to switch to non-root user
  notifies :restart, 'service[splunk]'
end

service 'splunk' do
  action node['init_package'] == 'systemd' ? %i(start enable) : :start
  supports status: true, restart: true
  notifies :run, "execute[#{splunk_cmd} stop]", :before unless correct_runas_user?
  provider splunk_service_provider
end

# if the splunk daemon is running as root, executing a normal service restart or stop will fail if the boot
# start script has been modified to execute splunk as a non-root user.
# So, the splunk daemon must be run this way instead
execute "#{splunk_cmd} stop" do
  action :nothing
  not_if { node['splunk']['server']['runasroot'] == true }
end
