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
require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# Creates a provider for the splunk_app resource.
class Chef::Provider::SplunkBaseProvider < Chef::Provider::LWRPBase

  def splunk_service
    service 'splunk' do
      action :nothing
      supports :status => true, :restart => true
      provider Chef::Provider::Service::Init
    end
  end

end
