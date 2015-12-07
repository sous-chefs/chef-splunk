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
require 'pathname'
require 'chef/provider/lwrp_base'
require_relative './helpers.rb'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# Creates a provider for the splunk_app resource.
class Chef
  class Provider
    class SplunkApp < Chef::Provider::LWRPBase
      provides :splunk_app if respond_to?(:provides)

      use_inline_resources

      def whyrun_supported?
        true
      end

      action :install do
        splunk_service
        install_dependencies unless new_resource.app_dependencies.empty?
        unless app_installed?
          if new_resource.cookbook_file
            app_package = local_file(new_resource.cookbook_file)
            cookbook_file app_package do
              source new_resource.cookbook_file
              cookbook new_resource.cookbook
              checksum new_resource.checksum
              notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
            end
          elsif new_resource.remote_file
            app_package = local_file(new_resource.remote_file)
            remote_file app_package do
              source new_resource.remote_file
              checksum new_resource.checksum
              notifies :run, "execute[splunk-install-#{new_resource.app_name}]", :immediately
            end
          elsif new_resource.remote_directory
            app_package = app_dir
            remote_directory app_dir do
              source new_resource.remote_directory
              cookbook new_resource.cookbook
              notifies :restart, 'service[splunk]', :immediately
            end
          else
            fail("Could not find an installation source for splunk_app[#{new_resource.app_name}]")
          end

          dir = app_dir

          execute "splunk-install-#{new_resource.app_name}" do
            command "#{splunk_cmd} install app #{app_package} -auth #{splunk_auth(new_resource.splunk_auth)}"
            not_if { ::File.exist?("#{dir}/default/app.conf") }
          end
        end

        directory "#{app_dir}/local" do
          recursive true
          mode 00755
          owner node['splunk']['user']['username'] unless node['splunk']['server']['runasroot']
        end

        if new_resource.templates
          new_resource.templates.each do |t|
            template "#{app_dir}/local/#{t}" do
              source "#{new_resource.app_name}/#{t}.erb"
              mode 00644
              notifies :restart, 'service[splunk]'
            end
          end
        end
      end

      action :remove do
        splunk_service
        directory app_dir do
          action :delete
          recursive true
          notifies :restart, 'service[splunk]'
        end
      end

      action :enable do
        unless app_enabled? # ~FC023
          splunk_service
          execute "splunk-enable-#{new_resource.app_name}" do
            command "#{splunk_cmd} enable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
            notifies :restart, 'service[splunk]'
          end
        end
      end

      action :disable do
        if app_enabled? # ~FC023
          splunk_service
          execute "splunk-disable-#{new_resource.app_name}" do
            command "#{splunk_cmd} disable app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}"
            not_if { ::File.exist?("#{splunk_dir}/etc/disabled-apps/#{new_resource.app_name}") }
            notifies :restart, 'service[splunk]'
          end
        end
      end

      private

      def app_dir
        "#{splunk_dir}/etc/apps/#{new_resource.app_name}"
      end

      def local_file(source)
        "#{Chef::Config[:file_cache_path]}/#{Pathname(source).basename}"
      end

      def app_enabled?
        s = shell_out("#{splunk_cmd} display app #{new_resource.app_name} -auth #{splunk_auth(new_resource.splunk_auth)}")
        s.run_command
        if s.stdout.empty?
          false
        else
          s.stdout.split[2] == 'ENABLED'
        end
      end

      def app_installed?
        ::File.exist?("#{app_dir}/default/app.conf")
      end

      def splunk_service
        service 'splunk' do
          action :nothing
          supports status: true, restart: true
          provider Chef::Provider::Service::Init
        end
      end

      def install_dependencies
        new_resource.app_dependencies.each do |pkg|
          package pkg
        end
      end
    end
  end
end
