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

  def cached_package
    "#{Chef::Config[:file_cache_path]}/#{package_file}"
  end

  def local_package_resource
    case node['platform_family']
    when 'rhel', 'fedora', 'suse', 'amazon'  then :rpm_package
    when 'debian'                            then :dpkg_package
    end
  end

  def splunk_service
    service 'splunk' do
      action :nothing
      supports status: true, restart: true
      provider splunk_service_provider
      action node['init_package'] == 'systemd' ? %i(start enable) : :start
    end
  end
end

action :run do
  return if splunk_installed?

  remote_file cached_package do
    source new_resource.url
    action :create_if_missing
  end

  declare_resource local_package_resource, new_resource.name do
    source cached_package.gsub(/\.Z/, '')
    version package_file[/#{new_resource.name}-([^-]+)/, 1]
  end
end

action :remove do
  begin
    resources('service[splunk]')
  rescue Chef::Exceptions::ResourceNotFound
    splunk_service
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
