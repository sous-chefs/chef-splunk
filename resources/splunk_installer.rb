#
# Author: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2019-2020
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
provides :splunk_installer
unified_mode true
resource_name :splunk_installer

property :url, String
property :package_name, String, name_property: true
property :version, String

action_class do
  def package_file
    if new_resource.url.empty? || new_resource.url.nil?
      "#{new_resource.package_name}-#{new_resource.version}"
    else
      splunk_file(new_resource.url)
    end
  end

  def package_version
    new_resource.version || package_file[/#{new_resource.name}-([^-]+)/, 1]
  end

  def cached_package
    "#{Chef::Config[:file_cache_path]}/#{package_file}"
  end

  def download_package
    remote_file package_file do
      backup false
      mode '644'
      path cached_package
      source new_resource.url
      action :create
    end
  end
end

action :run do
  return if splunk_installed?

  download_package

  if platform_family?('debian')
    dpkg_package new_resource.name do
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
      notifies :start, 'service[splunk]' unless node['splunk'].attribute?('disabled') && node['splunk']['disabled'] == true
    end
  else
    package new_resource.name do
      package_name new_resource.package_name
      source cached_package
      version package_version unless ::File.exist?(cached_package)
      notifies :start, 'service[splunk]' unless node['splunk'].attribute?('disabled') && node['splunk']['disabled'] == true
    end
  end
end

action :upgrade do
  return unless splunk_installed?

  download_package

  if platform_family?('debian')
    dpkg_package new_resource.name do
      action :upgrade
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
      notifies :start, 'service[splunk]' unless node['splunk'].attribute?('disabled') && node['splunk']['disabled'] == true
    end
  else
    package new_resource.name do
      action :upgrade
      package_name new_resource.package_name
      source cached_package
      version package_version unless ::File.exist?(cached_package)
      notifies :start, 'service[splunk]' unless node['splunk'].attribute?('disabled') && node['splunk']['disabled'] == true
    end
  end
end

action :remove do
  log 'splunk_install remove action failed: Splunk was not installed' do
    level :warn
    not_if { splunk_installed? }
  end

  service 'Splunk' do
    service_name server? ? 'Splunkd' : 'SplunkForwarder'
    action systemd? ? %i(stop disable) : :stop
  end

  package new_resource.name do
    action :remove
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

  startup_files = if server? && systemd?
                    [
                      '/etc/systemd/system/splunk.service',
                      '/etc/systemd/system/Splunkd.service',
                    ]
                  elsif systemd?
                    [
                      '/etc/systemd/system/splunk.service',
                      '/etc/systemd/system/SplunkForwarder.service',
                    ]
                  else
                    [ '/etc/init.d/splunk' ]
                  end

  (startup_files << cached_package).each do |f|
    file f do
      action :delete
      backup false
    end
  end

  # one final step to ensure nothing is left running
  execute 'pkill -9 splunkd' do
    user 'root'
    ignore_failure :quiet
  end
end
