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
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# Creates a provider for the splunk_app resource.
class Chef
  class Provider
    class SplunkApp < Chef::Provider::LWRPBase
      provides :splunk_app

      action :install do
        splunk_service
        setup_app_dir
        install
        custom_app_configs
      end

      action :update do
        splunk_service
        setup_app_dir
        if app_installed?
          install(true)
        else
          install
        end
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

      action :enable do
        # delay in case an install was previously executed prior to enable, so
        # splunk can catch up
        5.times do |i|
          break if app_installed?
          ::Chef::Log.info "Waiting for Splunk App Install: retries #{4 - i}/5 left"
          sleep 30
        end

        if app_enabled?
          ::Chef::Log.debug "#{new_resource.app_name} is enabled"
          return
        end

        splunk_service
        execute "splunk-enable-#{new_resource.app_name}" do
          sensitive false
          command "#{splunk_cmd} enable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
          notifies :restart, 'service[splunk]'
        end
      end

      action :disable do
        return unless app_enabled?
        splunk_service
        execute "splunk-disable-#{new_resource.app_name}" do
          sensitive false
          command "#{splunk_cmd} disable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
          not_if { ::File.exist?("#{splunk_dir}/etc/disabled-apps/#{new_resource.app_name}") }
          notifies :restart, 'service[splunk]'
        end
      end

      private

      def setup_app_dir
        dir = app_dir # this grants chef resources access to the private `#app_dir`

        install_dependencies unless new_resource.app_dependencies.empty?
        return if [new_resource.cookbook_file, new_resource.remote_file, new_resource.remote_directory].compact.empty?

        if new_resource.cookbook_file
          app_package = local_file(new_resource.cookbook_file)
          cookbook_file app_package do
            source new_resource.cookbook_file
            cookbook new_resource.cookbook
            checksum new_resource.checksum
            owner splunk_runas_user
            group splunk_runas_user
            notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
          end
        elsif new_resource.remote_file
          app_package = local_file(new_resource.remote_file)
          remote_file app_package do
            source new_resource.remote_file
            checksum new_resource.checksum
            owner splunk_runas_user
            group splunk_runas_user
            notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
          end
        elsif new_resource.remote_directory
          remote_directory dir do
            source new_resource.remote_directory
            cookbook new_resource.cookbook
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
            template_variables = if new_resource.template_variables.key?(destination)
                                   new_resource.template_variables[destination]
                                 else
                                   new_resource.template_variables['default']
                                 end

            template "#{dir}/#{destination}" do
              source source
              cookbook new_resource.cookbook
              variables template_variables
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
              owner splunk_runas_user
              group splunk_runas_user
              mode '644'
              notifies :restart, 'service[splunk]'
            end
          end
        end
      end

      def install(update = false)
        dir = app_dir # this grants chef resources access to the private `#app_dir`
        command = if app_installed? && update == true
                    "#{splunk_cmd} install app #{dir} -update 1 -auth #{splunk_auth(new_resource.splunk_auth)}"
                  elsif !app_installed? && update == false
                    "#{splunk_cmd} install app #{dir} -auth #{splunk_auth(new_resource.splunk_auth)}"
                  end
        execute "splunk-install-#{new_resource.app_name}" do
          sensitive false
          command command
          not_if { command.nil? }
        end
      end

      def app_dir
        new_resource.app_dir || "#{splunk_dir}/etc/apps/#{new_resource.app_name}"
      end

      def local_file(source)
        "#{Chef::Config[:file_cache_path]}/#{Pathname(source).basename}"
      end

      def app_enabled?
        s = shell_out("#{splunk_cmd} display app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}")
        s.exitstatus == 0 && s.stdout.split[2] == 'ENABLED'
      end

      def app_installed?
        s = shell_out("#{splunk_cmd} display app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}")
        return_val = s.exitstatus == 0 && s.stdout.match?(/^#{new_resource.app_name}/)

        ::Chef::Log.debug s.stdout
        ::Chef::Log.debug s.stderr
        ::Chef::Log.debug s.exitstatus
        ::Chef::Log.debug "return: #{return_val}"

        return_val
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
