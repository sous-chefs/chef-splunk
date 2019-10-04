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
#
# assumes x86_64 only (is there any reason to test i386 anymore?)
default['splunk']['upgrade']['server_url'] = value_for_platform_family(
  %w(rhel fedora amazon) => 'https://download.splunk.com/products/splunk/releases/7.3.2/linux/splunk-7.3.2-c60db69f8e32-linux-2.6-x86_64.rpm',
  ['debian'] => 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.3.2&product=splunk&filename=splunk-7.3.2-c60db69f8e32-linux-2.6-amd64.deb&wget=true'
)

default['splunk']['upgrade']['forwarder_url'] = value_for_platform_family(
  %w(rhel fedora amazon) => 'https://download.splunk.com/products/universalforwarder/releases/7.3.2/linux/splunkforwarder-7.3.2-c60db69f8e32-linux-2.6-x86_64.rpm',
  ['debian'] => 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.3.2&product=universalforwarder&filename=splunkforwarder-7.3.2-c60db69f8e32-linux-2.6-amd64.deb&wget=true'
)
