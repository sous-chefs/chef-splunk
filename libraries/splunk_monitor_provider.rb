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
# Largely based on chef-splunk/libraries/splunk_app_provider.rb
#
require_relative './splunk_base_provider.rb'
require_relative './helpers.rb'

# Creates a provider for the splunk_app resource.
class Chef::Provider::SplunkMonitor < Chef::Provider::SplunkBaseProvider
  use_inline_resources if defined?(:use_inline_resources)

  def whyrun_supported?
    true
  end

  action :add do
    splunk_service
    unless in_list_monitor
      execute "splunk-add-monitor-#{new_resource.source}" do
        command "#{splunk_cmd} add monitor #{new_resource.source} -auth #{splunk_auth(new_resource.splunk_auth)}"
      end
    end
  end

  action :remove do
    splunk_service
    if in_list_monitor
      execute "splunk-remove-monitor-#{new_resource.source}" do
        command "#{splunk_cmd} remove monitor #{new_resource.source} -auth #{splunk_auth(new_resource.splunk_auth)}"
      end
    end
  end

  def in_list_monitor
    # grep for source name
    cmd = "#{splunk_cmd} list monitor -auth #{splunk_auth(new_resource.splunk_auth)} | grep '^\\s*#{new_resource.source}$'"
    result = shell_out(cmd)
    (result.exitstatus == 0) ? true: false
  end

end
