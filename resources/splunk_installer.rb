# frozen_string_literal: true

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

property :url, String
property :package_name, String, name_property: true
property :version, String
property :runas_user, String, default: 'splunk'

action_class do
  def server?
    new_resource.package_name == 'splunk'
  end

  def install_dir
    server? ? '/opt/splunk' : '/opt/splunkforwarder'
  end

  def splunk_installed?
    ::File.exist?("#{install_dir}/bin/splunk")
  end

  def splunk_file(uri)
    require 'pathname'
    require 'uri'
    Pathname.new(URI.parse(uri).path).basename.to_s
  end

  def package_file
    if new_resource.url.nil? || new_resource.url.empty?
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

  def tgz_package?
    package_file.end_with?('.tgz') || package_file.end_with?('.tar.gz')
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

  def install_tgz
    execute "extract #{package_file}" do
      command "tar -xzf #{cached_package} -C /opt"
      creates install_dir
    end

    execute "chown #{install_dir}" do
      command "chown -R #{new_resource.runas_user}:#{new_resource.runas_user} #{install_dir}"
    end
  end
end

action :run do
  return if splunk_installed?

  download_package

  if tgz_package?
    install_tgz
  elsif platform_family?('debian')
    dpkg_package new_resource.name do
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
    end
  elsif platform_family?('suse')
    rpm_package new_resource.name do
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
    end
  else
    package new_resource.name do
      package_name new_resource.package_name
      source cached_package
      version package_version unless ::File.exist?(cached_package)
    end
  end
end

action :upgrade do
  return unless splunk_installed?

  download_package

  if tgz_package?
    install_tgz
  elsif platform_family?('debian')
    dpkg_package new_resource.name do
      action :upgrade
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
    end
  elsif platform_family?('suse')
    rpm_package new_resource.name do
      action :upgrade
      package_name new_resource.package_name
      source cached_package
      version new_resource.version unless ::File.exist?(cached_package)
    end
  else
    package new_resource.name do
      action :upgrade
      package_name new_resource.package_name
      source cached_package
      version package_version unless ::File.exist?(cached_package)
    end
  end
end

action :remove do
  log 'splunk_install remove action failed: Splunk was not installed' do
    level :warn
    not_if { splunk_installed? }
  end

  service server? ? 'Splunkd' : 'SplunkForwarder' do
    action %i(stop disable)
  end

  unless tgz_package?
    package new_resource.name do
      action :remove
    end
  end

  user new_resource.runas_user do
    action :remove
  end

  group new_resource.runas_user do
    action :remove
  end

  directory install_dir do
    recursive true
    action :delete
  end

  startup_files = if server?
                    [
                      '/usr/lib/systemd/system/Splunkd.service',
                      '/etc/systemd/system/Splunkd.service',
                      '/etc/systemd/system/splunk.service',
                    ]
                  else
                    [
                      '/usr/lib/systemd/system/SplunkForwarder.service',
                      '/etc/systemd/system/SplunkForwarder.service',
                      '/etc/systemd/system/splunk.service',
                    ]
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
