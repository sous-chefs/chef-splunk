#
# Cookbook:: chef-splunk
# Libraries:: helpers
#
# Author: Joshua Timberman <joshua@chef.io>
# Contributor: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2014-2020, Chef Software, Inc <legal@chef.io>
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
module ChefSplunk
  module Helpers
    require 'socket'
    require 'chef/mixin/shell_out'
    include Chef::Mixin::ShellOut

    @shcluster_server_size = nil

    def boot_start_cmd(disable = nil)
      systemd_managed = systemd? ? 1 : 0

      # this command modifies the systemd unit file, so must be run as root
      if disable.nil? && run_as_root?
        "#{splunk_dir}/bin/splunk enable boot-start -systemd-managed #{systemd_managed} --accept-license"
      elsif disable.nil?
        "#{splunk_dir}/bin/splunk enable boot-start  -user #{splunk_runas_user} -systemd-managed #{systemd_managed} --accept-license"
      else
        "#{splunk_dir}/bin/splunk disable boot-start -systemd-managed #{systemd_managed} --accept-license"
      end
    end

    # returns the output of splunk's HASHED_PASSWORD command
    # this command produces a hash of a clear-text password that can be stored in user-seed.conf, for example
    def hash_passwd(pw)
      return pw if pw.match?(/^\$\d*\$/)
      hash = shell_out("#{splunk_dir}/bin/splunk hash-passwd #{pw}")
      hash.stdout.strip
    end

    def license_accepted?
      node['splunk']['accept_license'] == true
    end

    def splunk_installed?
      ::File.exist?("#{splunk_dir}/bin/splunk")
    end

    def splunk_file(uri)
      require 'pathname'
      require 'uri'
      Pathname.new(URI.parse(uri).path).basename.to_s
    end

    def splunk_cmd(*args)
      cmd = "#{splunk_dir}/bin/splunk #{args.join(' ')}"

      return cmd if splunk_runas_user == 'root'
      "su - #{splunk_runas_user} -c '#{cmd}'"
    end

    # a way to return the right command to stop, start, and restart the splunk
    # service based on license acceptance and run-as user
    def svc_command(action = 'start')
      unless license_accepted?
        Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
        Chef::Log.fatal('Splunk is stopped and cannot be restarted until the license is accepted!')
        raise "Failed to #{action}"
      end

      splunk_cmd("#{action} --answer-yes --no-prompt --accept-license")
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

    def splunk_login_successful?
      return false unless splunk_installed?
      login = shell_out(splunk_cmd(['login', '-auth', node.run_state['splunk_auth_info']]))
      login.stderr.strip.empty? && login.stdout.strip.empty? && login.exitstatus == 0
    end

    def run_as_root?
      node['splunk']['server']['runasroot'] == true
    end

    def splunk_runas_user
      return 'root' if node['splunk']['server']['runasroot'] == true
      node['splunk']['user']['username']
    end

    def splunk_service_provider
      if systemd?
        Chef::Provider::Service::Systemd
      else
        Chef::Provider::Service::Init
      end
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

    def current_mgmt_port
      splunk = shell_out(splunk_cmd("show splunkd-port -auth #{node.run_state['splunk_auth_info']} | awk -F: '{print$NF}'"))
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
      splunk = shell_out("ps -ef|grep splunk|grep -v grep|awk '{print$1}'|uniq")
      splunk_runas_user == splunk.stdout
    end

    def multisite_clustering?
      node['splunk']['clustering']['num_sites'] > 1
    end

    def cluster_master?
      node['splunk']['clustering']['mode'] == 'master'
    end

    def init_shcluster_member?
      return false unless splunk_installed?
      list_member_info = shell_out(splunk_cmd("list shcluster-member-info -auth #{node.run_state['splunk_auth_info']}"))
      list_member_info.error?
    end

    def shcluster_servers_list
      # search head cluster member list needed to bootstrap the shcluster captain
      servers = [node['splunk']['shclustering']['mgmt_uri']]

      # unless shcluster members are staticly assigned via the node attribute,
      # try to find the other shcluster members via Chef search
      # if node['splunk']['shclustering']['mode'] == 'captain' &&
      if node['splunk']['shclustering']['shcluster_members'].empty?
        search(
          :node,
          "\
          splunk_shclustering_enabled:true AND \
          splunk_shclustering_label:#{node['splunk']['shclustering']['label']} AND \
          splunk_shclustering_mode:member AND \
          chef_environment:#{node.chef_environment}",
          filter_result: { 'member_mgmt_uri' => %w(splunk shclustering mgmt_uri) }
        ).each do |result|
          servers << result['member_mgmt_uri']
        end
      else
        servers = node['splunk']['shclustering']['shcluster_members']
      end
      servers
    end

    def shcluster_servers_size
      @shcluster_server_size ||= shcluster_servers_list.size
    end

    def shcluster_members_ipv4
      splunk = shell_out(splunk_cmd("list shcluster-members -auth #{node.run_state['splunk_auth_info']} | grep host_port_pair | awk -F: '{print$2}'"))
      return [] if splunk.stdout.strip == 'Encountered some errors while trying to obtain shcluster status.'
      splunk.stdout.split
    end

    def shcluster_member?
      shcluster_members_ipv4.include? "host_port_pair:#{node['ipaddress']}:8089"
    end

    def shcaptain_elected?
      shcluster_captain.nil?
    end

    def shcluster_captain
      return unless splunk_installed?

      command = splunk_cmd("show shcluster-status -auth '#{node.run_state['splunk_auth_info']}' | grep -A 5 Captain | tail -1'")
      shcluster_captain = shell_out(command)
      stdout = shcluster_captain.stdout.strip
      return unless stdout.match(/^label \: .*/)
      stdout.split(':').collect(&:strip)[1]
    end

    def ok_to_bootstrap_captain?
      return false unless splunk_installed?
      node['splunk']['shclustering']['captain_elected'] == false && node['splunk']['shclustering']['mode'] == 'captain' && shcluster_servers_size >= 2
    end

    def ok_to_add_member?
      return false unless splunk_installed?
      shcaptain_elected? && !shcluster_member?
    end

    def search_heads_peered?
      return false unless splunk_installed?
      list_search_server = shell_out(splunk_cmd("list search-server -auth #{node.run_state['splunk_auth_info']}"))
      list_search_server.stdout.match?(/(^Server at URI \".*\" with status as \"Up\")+/)
    end

    def upgrade_enabled?
      node['splunk']['upgrade_enabled'] == true
    end

    def systemd?
      ps1 = shell_out('ps --no-headers 1')
      ps1.stdout.strip.match?(/systemd/)
    end
  end
end

::Chef::DSL::Universal.include ::ChefSplunk::Helpers
