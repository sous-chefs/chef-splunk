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

include_recipe 'chef-splunk' unless splunk_installed?

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

include_recipe 'chef-splunk::setup_auth' if setup_auth?

# If we run as splunk user do a recursive chown to that user for all splunk
# files if a few specific files are root owned.
ruby_block 'splunk_fix_file_ownership' do
  action :run
  block do
    begin
      FileUtils.chown_R(splunk_runas_user, splunk_runas_user, splunk_dir)
    rescue Errno::ENOENT => e
      Chef::Log.warn "Possible transient file encountered in Splunk while setting ownership:\n#{e.message}"
    end
  end
  subscribes :run, 'service[splunk]', :before
end

# if the splunk daemon is running as root, executing a normal service restart or stop will fail if the boot
# start script has been modified to execute splunk as a non-root user.
# So, the splunk daemon must be run this way instead
execute 'splunk stop' do
  command splunk_cmd('stop')
  action :nothing
  subscribes :run, 'execute[splunk enable boot-start]', :before
end

file '/etc/init.d/splunk' do
  action :delete
  only_if { systemd? }
end

execute "splunk #{disabled? ? 'disable' : 'enable'} boot-start" do
  command boot_start_cmd(disabled? ? true : nil)
  sensitive false
  retries 3
  creates node['splunk']['startup_script']
  umask node['splunk']['enable_boot_start_umask']
end

link '/etc/systemd/system/splunk.service' do
  to server? ? '/etc/systemd/system/Splunkd.service' : '/etc/systemd/system/SplunkForwarder.service'
  only_if { systemd? }
end

default_service_action = if node['splunk']['disabled'] == true
                           :stop
                         elsif systemd?
                           %i(start enable)
                         else
                           :start
                         end

service 'splunk' do
  service_name node['splunk']['service_name']
  action default_service_action
  supports status: true, restart: true
  status_command svc_command('status')
  timeout 1800
  provider splunk_service_provider
  only_if { ::File.exist?(node['splunk']['startup_script']) }
  unless disabled?
    subscribes :restart, 'file[user-seed.conf]', :immediately
    subscribes :restart, "user[#{node['splunk']['user']['username']}]", :immediately
  end
end
