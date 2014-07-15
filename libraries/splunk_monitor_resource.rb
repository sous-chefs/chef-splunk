#
# Author: Jameson Lee <jameson@hey.co>
# Copyright (c) 2014, Hey, Inc.
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
# Largely based on chef-splunk's splunk_app_resource
#
require 'chef/resource/lwrp_base'

# Creates a splunk_app resource.
class Chef::Resource::SplunkMonitor < Chef::Resource::LWRPBase
  self.resource_name = 'splunk_monitor'

  # Actions correspond to splunk commands pertaining to apps.
  actions :add, :remove
  default_action :add

  attribute :source, :kind_of => String, :name_attribute => true
  attribute :splunk_auth, :kind_of => String, :required => true
end
