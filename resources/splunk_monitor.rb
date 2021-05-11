#
# Author: Dang H. Nguyen <dang.nguyen@disney.com>
# Copyright:: 2020
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
provides :splunk_monitor
unified_mode true
resource_name :splunk_monitor

# the dictionary is created from documentation on Splunk's website
# See https://docs.splunk.com/@documentation/Splunk/8.0.2/Data/Listofpretrainedsourcetypes
dictionary = {
  'Application Servers' => %w(
    log4j log4php weblogic_stdout websphere_activity websphere_core
    websphere_trlog catalina ruby_on_rails
  ),
  'Databases' => %w(db2_diag mysqld mysqld_error mysqld_bin mysqld_slow),
  'E-mail' => %w(
    exim_main exim_reject postfix_syslog sendmail_syslog procmail
  ),
  'Operating systems' => %w(
    linux_messages_syslog linux_secure linux_audit linux_bootlog anaconda
    anaconda_syslog osx_asl osx_crashreporter osx_crash_log osx_install
    osx_secure osx_daily osx_weekly osx_monthly osx_window_server
    windows_snare_syslog dmesg ftp ssl_error syslog sar rpmpkgs
  ),
  'Network' => %w(novell_groupwise tcp),
  'Printers' => %w(cups_access cups_error spooler),
  'Routers and firewalls' => %w(
    cisco_cdr cisco:asa cisco_syslog clavister
  ),
  'VoIP' => %w(
    asterisk_cdr asterisk_event asterisk_messages asterisk_queue
  ),
  'Webservers' => %w(
    access_combined access_combined_wcookie access_common
    apache_error iis
  ),
  'Splunk' => %w(
    splunk_com_php_error splunkd splunkd_crash_log splunkd_misc
    splunkd_stderr splunk-blocksignature splunk_directory_monitor
    splunk_directory_monitor_misc splunk_search_history
    splunkd_remote_searches splunkd_access splunkd_ui_access
    splunk_web_access splunk_web_service splunkd_conf django_access
    django_service django_error splunk_help mongod
  ),
  'Non-Log files' => %w(
    csv psv tsv _json json_no_timestamp fs_notification exchange
    generic_single_line
  ),
  'Miscellaneous' => %w(
    snort splunk_disk_objects splunk_resource_usage kvstore
  ),
}

pretrained_sourcetypes = dictionary.values.flatten.sort.uniq

builtin_indexes = %w(
  _internal access_combined access_combined_wcookie apache_error
  catalina cisco_syslog history linux_messages_syslog linux_secure
  log4j main os postfix_syslog rabbitmq sample shared_json splunklogger
)

# these properties are specific to this resource
property :monitor_name, kind_of: String, name_property: true, regex: %r{^monitor:///.*},
                        coerce: proc { |m| "monitor://#{m}" }
property :inputs_conf_path, kind_of: String, regex: %r{^/.*}, desired_state: false, required: true
property :backup, kind_of: [FalseClass, Integer], default: 5, desired_state: false

# These resource properties are drawn from Splunk's @documentation.
# Refer to https://docs.splunk.com/@documentation/Splunk/8.0.2/Data/Monitorfilesanddirectorieswithinputs.conf
# for more detailed description of these properties
property :host, kind_of: String, default: nil
property :index, kind_of: String, equal_to: builtin_indexes, default: '_internal'
property :sourcetype, kind_of: String, equal_to: pretrained_sourcetypes
property :queue, kind_of: String, equal_to: %w(parsingQueue indexQueue), default: 'parsingQueue'
property :_TCP_ROUTING, kind_of: String, default: '*'
property :host_regex, kind_of: String, default: nil
property :host_segment, kind_of: Integer, default: nil

# The following are additional settings you can use when defining `monitor` input stanzas
property :source, kind_of: String, default: nil
property :crcSalt, kind_of: String, default: '<SOURCE>'
property :ignoreOlderThan, kind_of: String, default: nil, regex: [ /^(0|[1-9]+[dhms])$/ ]
property :followTail, kind_of: Integer, default: 0, equal_to: [0, 1]
property :whitelist, kind_of: String, default: nil
property :blacklist, kind_of: String, default: nil
property :alwaysOpenFile, kind_of: Integer, default: 0, equal_to: [0, 1]
property :recursive, kind_of: [TrueClass, FalseClass], default: true
property :time_before_close, kind_of: Integer, default: 3
property :followSymlink, kind_of: [TrueClass, FalseClass], default: true

@document = nil
@stanza_title = nil

action_class do
  include Splunk::Resources::Helpers

  def new_value_to_option(option)
    value = new_resource.send(option)
    @document[@stanza_title][option] = value
  end

  def do_create
    # this is an array of this resource's properties that align with Splunk's monitor settings
    options = %w(
      host index sourcetype queue _TCP_ROUTING host_regex host_segment source crcSalt ignoreOlderThan followTail
      whitelist blacklist alwaysOpenFile recursive time_before_close followSymlink
    )
    updated = []

    unless @document.has_section?(@stanza_title)
      converge_by("Adding stanza [#{@stanza_title}]") do
        add_new_section
        updated << true if @document.has_section?(@stanza_title)
      end
    end

    options.each do |option|
      value = new_resource.send(option)
      if @document[@stanza_title].lines.keys.include?(option) && (value.nil? || !property_is_set?(option.to_sym))
        converge_by("removing #{option} from [#{@stanza_title}]") do
          remove_option_from_section(option)
          updated << true unless @document[@stanza_title].has_option?(option)
        end
      elsif !@document[@stanza_title].has_option?(option) && property_is_set?(option.to_sym)
        converge_by("adding '#{option} = #{value}' in [#{@stanza_title}]") do
          new_value_to_option(option)
          updated << true if @document[@stanza_title].has_option?(option) && value == @document[@stanza_title][option]
        end
      elsif @document[@stanza_title].has_option?(option) && value != @document[@stanza_title][option]
        converge_by("updating '#{option} = #{value}' in [#{@stanza_title}]") do
          new_value_to_option(option)
          updated << true if value == @document[@stanza_title][option]
        end
      end
    end

    if @document[@stanza_title].lines.keys.empty?
      converge_by("removing stanza [#{@stanza_title}]") do
        remove_section(@stanza_title)
        updated << true unless @document.has_section?(@stanza_title)
      end
    end

    updated.any?
  end
end

action :create do
  @document ||= IniParse.parse(::File.read(new_resource.inputs_conf_path))
  @stanza_title = new_resource.monitor_name
  save_doc(new_resource.inputs_conf_path) if do_create
end

action :remove do
  @document ||= IniParse.parse(::File.read(new_resource.inputs_conf_path))
  @stanza_title = new_resource.monitor_name.to_s
  save_doc(new_resource.inputs_conf_path) if do_remove
end
