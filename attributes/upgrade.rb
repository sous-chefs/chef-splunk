#
# Cookbook:: chef-splunk
# Attributes:: upgrade
#
# Copyright:: 2014-2016, Chef Software, Inc.
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
if node['splunk']['upgrade_enabled']
  case node['platform_family']
  when 'rhel', 'fedora'
    if node['kernel']['machine'] == 'x86_64'
      default['splunk']['upgrade']['server_url'] = 'http://download.splunk.com/releases/4.3.7/splunk/linux/splunk-4.3.7-181874-linux-2.6-x86_64.rpm'
      default['splunk']['upgrade']['forwarder_url'] = 'http://download.splunk.com/releases/4.3.7/universalforwarder/linux/splunkforwarder-4.3.7-181874-linux-2.6-x86_64.rpm'
    else
      default['splunk']['upgrade']['server_url'] = 'http://download.splunk.com/releases/4.3.7/splunk/linux/splunk-4.3.7-181874.i386.rpm'
      default['splunk']['upgrade']['forwarder_url'] = 'http://download.splunk.com/releases/4.3.7/universalforwarder/linux/splunkforwarder-4.3.7-181874.i386.rpm'
    end
  when 'debian'
    if node['kernel']['machine'] == 'x86_64'
      default['splunk']['upgrade']['server_url'] = 'http://download.splunk.com/releases/4.3.7/splunk/linux/splunk-4.3.7-181874-linux-2.6-amd64.deb'
      default['splunk']['upgrade']['forwarder_url'] = 'http://download.splunk.com/releases/4.3.7/universalforwarder/linux/splunkforwarder-4.3.7-181874-linux-2.6-amd64.deb'
    else
      default['splunk']['upgrade']['server_url'] = 'http://download.splunk.com/releases/4.3.7/splunk/linux/splunk-4.3.7-181874-linux-2.6-intel.deb'
      default['splunk']['upgrade']['forwarder_url'] = 'http://download.splunk.com/releases/4.3.7/universalforwarder/linux/splunkforwarder-4.3.7-181874-linux-2.6-intel.deb'
    end
  when 'omnios'
    default['splunk']['upgrade']['server_url'] = 'http://download.splunk.com/releases/4.3.7/splunk/solaris/splunk-4.3.7-181874-solaris-10-intel.pkg.Z'
    default['splunk']['upgrade']['forwarder_url'] = 'http://download.splunk.com/releases/4.3.7/universalforwarder/solaris/splunkforwarder-4.3.7-181874-solaris-10-intel.pkg.Z'
  end
end
