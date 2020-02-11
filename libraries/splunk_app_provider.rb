#
# Author: Joshua Timberman <joshua@chef.io>
# Contributor: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2014-2020, Chef Software, Inc <legal@chef.io>
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
require 'pathname'
require 'chef/provider/lwrp_base'
require_relative './helpers.rb'

# Creates a provider for the splunk_app resource.
class Chef
  class Provider
    class SplunkApp < Chef::Provider::LWRPBase
      provides :splunk_app

      action :install do
        splunk_service
        setup_app_dir
        custom_app_configs
      end

      action :remove do
        dir = app_dir # this grants chef resources access to the private `#app_dir`

        splunk_service
        directory dir do
          action :delete
          recursive true
          notifies :restart, 'service[splunk]'
        end
      end

      private

      def setup_app_dir
        dir = app_dir # this grants chef resources access to the value returned by private method `#app_dir`

        return if [new_resource.cookbook_file, new_resource.remote_file, new_resource.remote_directory].compact.empty?
        install_dependencies unless new_resource.app_dependencies.empty?

        directory dir do
          recursive true
          mode '755'
          owner splunk_runas_user
          group splunk_runas_user
        end

        directory "#{dir}/local" do
          recursive true
          mode '755'
          owner splunk_runas_user
          group splunk_runas_user
        end if new_resource.cookbook_file || new_resource.remote_file

        if new_resource.cookbook_file
          app_package = "#{dir}/local/#{::File.basename(new_resource.cookbook_file)}"

          cookbook_file new_resource.cookbook_file do
            path app_package
            source new_resource.cookbook_file
            sensitive new_resource.sensitive
            cookbook new_resource.cookbook
            checksum new_resource.checksum
            owner splunk_runas_user
            group splunk_runas_user
            notifies :restart, 'service[splunk]'
          end
        elsif new_resource.remote_file || new_resource.local_file
          app_package = "#{dir}/local/#{::File.basename(new_resource.remote_file)}"
          source = new_resource.remote_file

          if new_resource.local_file
            app_package = "#{dir}/local/#{::File.basename(new_resource.local_file)}"
            source = "file://#{new_resource.local_file}"
          end

          remote_file new_resource.remote_file do
            path app_package
            source source
            checksum new_resource.checksum
            sensitive new_resource.sensitive
            owner splunk_runas_user
            group splunk_runas_user
            notifies :restart, 'service[splunk]'
          end
        elsif new_resource.remote_directory
          remote_directory dir do
            source new_resource.remote_directory
            cookbook new_resource.cookbook
            sensitive new_resource.sensitive
            owner splunk_runas_user
            group splunk_runas_user
            files_owner splunk_runas_user
            files_group splunk_runas_user
            notifies :restart, 'service[splunk]'
          end
        end
      end

      def custom_app_configs
        dir = app_dir # this grants chef resources access to the private `#app_dir`

        if new_resource.templates.class == Hash
          # create the templates with destination paths relative to the target app_dir
          # Hash should be key/value where the key indicates a destination path (including file name),
          # and value is the name of the template source
          new_resource.templates.each do |destination, source|
            directory "#{dir}/#{::File.dirname(destination)}" do
              recursive true
              mode '755'
              owner splunk_runas_user
              group splunk_runas_user
            end

            # TODO: DRY this handling of template_variables with that of lines 173-188
            template_variables = if new_resource.template_variables.key?(source)
                                   new_resource.template_variables[source]
                                 else
                                   new_resource.template_variables['default']
                                 end

            template "#{dir}/#{destination}" do
              source source
              cookbook new_resource.cookbook
              variables template_variables
              sensitive new_resource.sensitive
              owner splunk_runas_user
              group splunk_runas_user
              mode '644'
              notifies :restart, 'service[splunk]'
            end
          end
        else
          directory "#{dir}/local" do
            recursive true
            mode '755'
            owner splunk_runas_user
            group splunk_runas_user
          end

          new_resource.templates.each do |t|
            template_variables = if new_resource.template_variables.key?(t)
                                   new_resource.template_variables[t]
                                 else
                                   new_resource.template_variables['default']
                                 end
            t = t.match?(/(\.erb)*/) ? ::File.basename(t, '.erb') : t

            template "#{dir}/local/#{t}" do
              source "#{new_resource.app_name}/#{t}.erb"
              cookbook new_resource.cookbook
              variables template_variables
              sensitive new_resource.sensitive
              owner splunk_runas_user
              group splunk_runas_user
              mode '644'
              notifies :restart, 'service[splunk]'
            end
          end
        end
      end

      def app_dir
        new_resource.app_dir || "#{splunk_dir}/etc/apps/#{new_resource.app_name}"
      end

      def app_installed?
        ::File.exist?(app_dir)
      end

      def splunk_service
        # during an initial install, the start/restart commands must deal with accepting
        # the license. So, we must ensure the service[splunk] resource
        # properly deals with the license.
        edit_resource(:service, 'splunk') do
          action node['init_package'] == 'systemd' ? %i(start enable) : :start
          supports status: true, restart: true
          stop_command svc_command('stop')
          start_command svc_command('start')
          restart_command svc_command('restart')
          status_command svc_command('status')
          provider splunk_service_provider
        end
      end

      def install_dependencies
        package new_resource.app_dependencies
      end
    end
  end
end
