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
require 'chef/resource/lwrp_base'

# Creates a splunk_app resource.
class Chef
  class Resource
    class SplunkApp < Chef::Resource::LWRPBase
      self.resource_name = 'splunk_app'

      # Actions correspond to splunk commands pertaining to apps.
      actions :enable, :disable, :install, :remove
      default_action :enable
      state_attrs :enabled, :installed

      attribute :app_name, kind_of: String, name_attribute: true
      attribute :remote_file, kind_of: String, default: nil
      attribute :cookbook_file, kind_of: String, default: nil
      attribute :cookbook, kind_of: String, default: nil
      attribute :checksum, kind_of: String, default: nil
      attribute :remote_directory, kind_of: String, default: nil
      attribute :splunk_auth, kind_of: [String, Array], required: true
      attribute :app_dependencies, kind_of: Array, default: []
      attribute :templates, kind_of: [Array, Hash], default: []
      attribute :enabled, kind_of: [TrueClass, FalseClass, NilClass], default: false
      attribute :installed, kind_of: [TrueClass, FalseClass, NilClass], default: false
    end
  end
end
