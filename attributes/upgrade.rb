#
# Cookbook:: chef-splunk
# Attributes:: upgrade
#
# Copyright:: 2014-2019, Chef Software, Inc.
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

# assumes x86_64 only (is there any reason to test i386 anymore?)
default['splunk']['forwarder']['upgrade']['version'] = '8.0.1'
default['splunk']['server']['upgrade']['version'] = '8.0.1'

default['splunk']['server']['upgrade']['url'] = value_for_platform_family(
  %w(rhel fedora suse) => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
)

default['splunk']['forwarder']['upgrade']['url'] = value_for_platform_family(
  %w(rhel fedora suse) => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
)
