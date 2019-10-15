#
# Author: Dang H. Nguyen <dang.nguyen@disney.com>
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
resource_name :splunk_installer

property :url, String, name_property: true

action_class do
  def package_file
    splunk_file(new_resource.url)
  end

  def package_version
    package_file[/#{new_resource.name}-([^-]+)/, 1]
  end

  def cached_package
    "#{Chef::Config[:file_cache_path]}/#{package_file}"
  end

  def local_package_resource
    case node['platform_family']
    when 'rhel', 'fedora', 'suse', 'amazon'
      :rpm_package
    when 'debian'
      :dpkg_package
    end
  end
end

action :run do
  return if splunk_installed?

  # during an initial install, the start/restart commands must deal with accepting
  # the license. So, we must ensure the service[splunk] resource
  # properly deals with the license.
  edit_resource(:service, 'splunk') do
    action :nothing
    supports status: true, restart: true
    stop_command svc_command('stop')
    start_command svc_command('start')
    restart_command svc_command('restart')
    provider splunk_service_provider
  end

  remote_file package_file do
    backup false
    mode '644'
    path cached_package
    source new_resource.url
    use_conditional_get true
    use_etag true
    action :create
  end

  declare_resource local_package_resource, new_resource.name do
    source cached_package.gsub(/\.Z/, '')
    version package_version
    notifies :start, 'service[splunk]'
  end
end

action :upgrade do
  return unless splunk_installed?

  # during an upgrade, the start/restart commands must deal with accepting
  # the license. So, we must ensure the service[splunk] resource
  # properly deals with the license.
  edit_resource(:service, 'splunk') do
    action :stop
    supports status: true, restart: true
    stop_command svc_command('stop')
    start_command svc_command('start')
    restart_command svc_command('restart')
    provider splunk_service_provider
  end

  remote_file package_file do
    backup false
    mode '644'
    path cached_package
    source new_resource.url
    use_conditional_get true
    use_etag true
    action :create
  end

  declare_resource local_package_resource, new_resource.name do
    action :upgrade
    source cached_package.gsub(/\.Z/, '')
    version package_version
    notifies :stop, 'service[splunk]', :before
    # forwarders can be restarted immediately; otherwise, wait until the end
    if package_file =~ /splunkforwarder/
      notifies :start, 'service[splunk]', :immediately
    else
      notifies :start, 'service[splunk]'
    end
  end
end

action :remove do
  find_resource(:service, 'splunk') do
    supports status: true, restart: true
    provider splunk_service_provider
    action node['init_package'] == 'systemd' ? %i(stop disable) : :stop
  end

  declare_resource local_package_resource, new_resource.name do
    action :remove
    notifies :stop, 'service[splunk]', :before
  end

  user node['splunk']['user']['username'] do
    action :remove
  end

  group node['splunk']['user']['username'] do
    action :remove
  end

  directory splunk_dir do
    recursive true
    action :delete
  end

  file package_file do
    action :delete
    path cached_package
    backup false
  end
end
