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
require 'pathname'

provides :splunk_app
unified_mode true
resource_name :splunk_app

property :app_name, kind_of: String, name_property: true
property :app_dependencies, kind_of: Array, default: []
property :app_dir, kind_of: String, default: nil
property :checksum, kind_of: String, default: nil
property :cookbook, kind_of: String, default: nil
property :cookbook_file, kind_of: String, default: nil
property :installed, kind_of: [TrueClass, FalseClass, NilClass], default: false
property :local_file, kind_of: String, default: nil
property :remote_file, kind_of: String, default: nil
property :remote_directory, kind_of: String, default: nil
property :templates, kind_of: [Array, Hash], default: []
property :files_mode, [String, Integer, nil],
          description: "The octal mode for a file.\n UNIX- and Linux-based systems: A quoted 3-5 character string that defines the octal mode that is passed to chmod. For example: '755', '0755', or 00755. If the value is specified as a quoted string, it works exactly as if the chmod command was passed. If the value is specified as an integer, prepend a zero (0) to the value to ensure that it is interpreted as an octal number. For example, to assign read, write, and execute rights for all users, use '0777' or '777'; for the same rights, plus the sticky bit, use 01777 or '1777'.\n Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: '755', '0755', or 00755. Values up to '0777' are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where 4 equals GENERIC_READ, 2 equals GENERIC_WRITE, and 1 equals GENERIC_EXECUTE. This property cannot be used to set :full_control. This property has no effect if not specified, but when it and rights are both specified, the effects are cumulative.",
          regex: /^\d{3,4}$/, default: nil
# template_variables is a Hash referencing
# each template named in the templates property, above, with each template having its
# unique set of variables and values
property :template_variables, kind_of: Hash, default: { 'default' => {} }

action_class do
  def setup_app_dir
    return if [new_resource.cookbook_file, new_resource.remote_file, new_resource.remote_directory].compact.empty?
    install_dependencies unless new_resource.app_dependencies.empty?

    directory app_dir do
      recursive true
      mode '755'
      owner splunk_runas_user
      group splunk_runas_user
    end

    directory "#{app_dir}/local" do
      recursive true
      mode '755'
      owner splunk_runas_user
      group splunk_runas_user
    end if new_resource.cookbook_file || new_resource.remote_file

    if new_resource.cookbook_file
      app_package = "#{app_dir}/local/#{::File.basename(new_resource.cookbook_file)}"

      cookbook_file new_resource.cookbook_file do
        cookbook new_resource.cookbook unless new_resource.cookbook.nil?
        path app_package
        source new_resource.cookbook_file
        sensitive new_resource.sensitive
        checksum new_resource.checksum
        owner splunk_runas_user
        group splunk_runas_user
        mode new_resource.files_mode unless new_resource.files_mode.nil?
      end
    elsif new_resource.remote_file || new_resource.local_file
      app_package = "#{app_dir}/local/#{::File.basename(new_resource.remote_file)}"
      source = new_resource.remote_file

      if new_resource.local_file
        app_package = "#{app_dir}/local/#{::File.basename(new_resource.local_file)}"
        source = "file://#{new_resource.local_file}"
      end

      remote_file new_resource.remote_file do
        path app_package
        source source
        checksum new_resource.checksum
        sensitive new_resource.sensitive
        owner splunk_runas_user
        group splunk_runas_user
      end
    elsif new_resource.remote_directory
      remote_directory app_dir do
        source new_resource.remote_directory
        sensitive new_resource.sensitive
        owner splunk_runas_user
        group splunk_runas_user
        files_owner splunk_runas_user
        files_group splunk_runas_user
        files_mode new_resource.files_mode unless new_resource.files_mode.nil?
      end
    end
  end

  def custom_app_configs
    if new_resource.templates.class == Hash
      # create the templates with destination paths relative to the target app_dir
      # Hash should be key/value where the key indicates a destination path (including file name),
      # and value is the name of the template source
      new_resource.templates.each do |destination, source|
        directory "#{app_dir}/#{::File.dirname(destination)}" do
          recursive true
          mode '755'
          owner splunk_runas_user
          group splunk_runas_user
        end

        # TODO: DRY this handling of template_variables with that of lines 134-138
        template_variables = if new_resource.template_variables.key?(source)
                               new_resource.template_variables[source]
                             else
                               new_resource.template_variables['default']
                             end

        template "#{app_dir}/#{destination}" do
          cookbook new_resource.cookbook unless new_resource.cookbook.nil?
          source source
          variables template_variables
          sensitive new_resource.sensitive
          owner splunk_runas_user
          group splunk_runas_user
          mode new_resource.files_mode unless new_resource.files_mode.nil?
        end
      end
    else
      directory "#{app_dir}/local" do
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

        template "#{app_dir}/local/#{t}" do
          cookbook new_resource.cookbook unless new_resource.cookbook.nil?
          source "#{new_resource.app_name}/#{t}.erb"
          variables template_variables
          sensitive new_resource.sensitive
          owner splunk_runas_user
          group splunk_runas_user
          mode new_resource.files_mode unless new_resource.files_mode.nil?
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

  def install_dependencies
    package new_resource.app_dependencies
  end
end

action :install do
  setup_app_dir
  custom_app_configs
end

action :remove do
  directory app_dir do
    action :delete
    recursive true
  end
end
