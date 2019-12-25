#
# Cookbook:: chef-splunk
# Libraries:: helpers
#
# Author: Joshua Timberman <joshua@chef.io>
# Copyright:: 2014-2016, Chef Software, Inc <legal@chef.io>
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
require 'socket'
require 'mixlib/shellout'

def splunk_installed?
  ::File.exist?(splunk_cmd)
end

def splunk_file(uri)
  require 'pathname'
  require 'uri'
  Pathname.new(URI.parse(uri).path).basename.to_s
end

def splunk_cmd
  "#{splunk_dir}/bin/splunk"
end

# a way to return the right command to stop, start, and restart the splunk
# service based on license acceptance and run-as user
def svc_command(action = 'start')
  unless license_accepted?
    Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
    Chef::Log.fatal('Splunk is stopped and cannot be restarted until the license is accepted!')
    raise "Failed to #{action}"
  end

  command = "#{splunk_cmd} #{action} --answer-yes --no-prompt --accept-license"

  return command if splunk_runas_user == 'root'
  "su - #{splunk_runas_user} -c '#{command}'"
end

def splunk_dir
  # Splunk Enterprise (Server) will install in /opt/splunk.
  # Splunk Universal Forwarder can be a used as a client or a forwarding
  # (intermediary) server which installs to /opt/splunkforwarder
  forwarderpath = '/opt/splunkforwarder'
  enterprisepath = '/opt/splunk'

  return enterprisepath if server?
  forwarderpath
end

def splunk_auth(auth)
  # if auth is a string, we assume it's correctly
  # defined as a splunk authentication string, like:
  #
  # admin:changeme
  #
  # if it is an array, we assume it has two elements that should be
  # joined with a : to make it defined as a splunk authentication
  # string (as above.
  case auth
  when String
    auth
  when Array
    auth.join(':')
  end
end

def splunk_runas_user
  return 'root' if node['splunk']['server']['runasroot'] == true
  node['splunk']['user']['username']
end

def splunk_service_provider
  if node['init_package'] == 'systemd'
    Chef::Provider::Service::Systemd
  else
    Chef::Provider::Service::Init
  end
end

def license_accepted?
  node['splunk']['accept_license'] == true
end

# a splunkd instance is either a splunk client (runs universal forwarder only) or a complete server
def server?
  node['splunk']['is_server'] == true
end

def port_open?(port, ip = '127.0.0.1')
  # TCPSocket will return a file descriptor if it can open the connection,
  # and raise Errno::ECONNREFUSED or Errno::ETIMEDOUT if it can't. We rescue
  # that exception and return false.
  begin
    ::TCPSocket.new(ip, port)
  rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
    return false
  end
  true
end

def current_mgmt_port(splunk_auth_info)
  splunk = Mixlib::ShellOut.new("#{splunk_cmd} show splunkd-port -auth #{splunk_auth_info} | awk -F: '{print$NF}'")
  splunk.run_command
  splunk.error! # Raise an exception if it didn't exit with 0
  splunk.stdout.strip
end

def disabled?
  node['splunk'].attribute?('disabled') &&
    node['splunk']['disabled'] == true
end

def setup_auth?
  node['splunk']['setup_auth'] == true
end

def enable_ssl?
  node['splunk']['ssl_options']['enable_ssl'] == true
end

def enable_clustering?
  node['splunk']['clustering']['enabled'] == true
end

def enable_shclustering?
  node['splunk']['shclustering']['enabled'] == true
end

# returns true if the splunkd process is owned by the correct "run-as" user
def correct_runas_user?
  splunk = Mixlib::ShellOut.new("ps -ef|grep splunk|grep -v grep|awk '{print$1}'|uniq")
  splunk.run_command
  splunk_runas_user == splunk.stdout
end
