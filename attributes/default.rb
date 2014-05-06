#
# Author: Joshua Timberman <joshua@getchef.com>
# Copyright (c) 2014, Chef Software, Inc <legal@getchef.com>
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
# Assume default use case is a Universal Forwarder (client).
default['splunk']['accept_license'] = false
default['splunk']['is_server']      = false
default['splunk']['receiver_port']  = '9997'

default['splunk']['user'] = {
  'username' => 'splunk',
  'comment'  => 'Splunk Server',
  'home'     => '/opt/splunkforwarder',
  'shell'    => '/bin/bash',
  'uid'      => 396
}

default['splunk']['ssl_options'] = {
  'enable_ssl' => false,
  'data_bag' => 'vault',
  'data_bag_item' => 'splunk_certificates',
  'keyfile' => 'self-signed.example.com.key',
  'crtfile' => 'self-signed.example.com.crt'
}

# If the `is_server` attribute is set (via an overridable location
# like a role), then set particular attribute defaults based on the
# server, rather than Universal Forwarder. We hardcode the path
# because we don't want to rely on automagic.
if node['splunk']['is_server']
  default['splunk']['user']['home'] = '/opt/splunk'
end

case node['platform_family']
when 'rhel'
  if node['kernel']['machine'] == 'x86_64'
    default['splunk']['forwarder']['url'] = 'http://download.splunk.com/releases/6.0.3/universalforwarder/linux/splunkforwarder-6.0.3-204106-linux-2.6-x86_64.rpm'
    default['splunk']['server']['url'] = 'http://download.splunk.com/releases/6.0.3/splunk/linux/splunk-6.0.3-204106-linux-2.6-x86_64.rpm'
  else
    default['splunk']['forwarder']['url'] = 'http://download.splunk.com/releases/6.0.3/universalforwarder/linux/splunkforwarder-6.0.3-204106.i386.rpm'
    default['splunk']['server']['url'] = 'http://download.splunk.com/releases/6.0.3/splunk/linux/splunk-6.0.3-204106.i386.rpm'
  end
when 'debian'
  if node['kernel']['machine'] == 'x86_64'
    default['splunk']['forwarder']['url'] = 'http://download.splunk.com/releases/6.0.3/universalforwarder/linux/splunkforwarder-6.0.3-204106-linux-2.6-amd64.deb'
    default['splunk']['server']['url'] = 'http://download.splunk.com/releases/6.0.3/splunk/linux/splunk-6.0.3-204106-linux-2.6-amd64.deb'
  else
    default['splunk']['forwarder']['url'] = 'http://download.splunk.com/releases/6.0.3/universalforwarder/linux/splunkforwarder-6.0.3-204106-linux-2.6-intel.deb'
    default['splunk']['server']['url'] = 'http://download.splunk.com/releases/6.0.3/splunk/linux/splunk-6.0.3-204106-linux-2.6-intel.deb'
  end
when 'omnios'
  default['splunk']['forwarder']['url'] = 'http://download.splunk.com/releases/6.0.3/universalforwarder/solaris/splunkforwarder-6.0.3-204106-SunOS-x86_64.tar.Z'
  default['splunk']['server']['url'] = 'http://download.splunk.com/releases/6.0.3/splunk/solaris/splunk-6.0.3-204106-solaris-10-intel.pkg.Z'
end
