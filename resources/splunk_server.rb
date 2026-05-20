# frozen_string_literal: true

provides :splunk_server
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunk'
property :package_name, String, default: 'splunk'
property :url, String, required: true
property :version, String
property :mgmt_port, Integer, default: 8089
property :receiver_port, Integer, default: 9997
property :web_port, Integer, default: 443
property :splunk_auth, String, sensitive: true, required: true
property :optimistic_file_locking, [true, false], default: false

action :install do
  splunk_installer new_resource.package_name do
    url new_resource.url
    version new_resource.version if new_resource.version
  end

  splunk_auth auth_user do
    install_dir new_resource.install_dir
    admin_user auth_user
    admin_password auth_password
  end

  splunk_service 'splunk' do
    install_dir new_resource.install_dir
    service_name 'Splunkd'
    runas_user new_resource.runas_user
    admin_user auth_user
    admin_password auth_password
    optimistic_file_locking new_resource.optimistic_file_locking
  end

  execute 'update-splunk-mgmt-port' do
    command mgmt_port_command
    sensitive true
    environment(
      'SPLUNK_USER' => auth_user,
      'SPLUNK_PASSWORD' => auth_password
    )
  end

  ruby_block 'update-splunk-receiver-port' do
    block { write_receiver_port_config }
    not_if { receiver_port_configured? }
  end

  file receiver_inputs_conf_path do
    owner new_resource.runas_user
    group new_resource.runas_user
    mode '600'
  end
end

action :remove do
  splunk_installer new_resource.package_name do
    url new_resource.url
    version new_resource.version if new_resource.version
    action :remove
  end
end

action_class do
  use 'splunk_auth_helpers'

  def splunk_cmd(args)
    cmd = "#{new_resource.install_dir}/bin/splunk #{args}"
    return cmd if new_resource.runas_user == 'root'
    "su - #{new_resource.runas_user} -c '#{cmd}'"
  end

  def mgmt_port_command
    splunk_cmd("set splunkd-port #{new_resource.mgmt_port} -auth '#{new_resource.splunk_auth}'")
  end

  def receiver_port_configured?
    require 'iniparse'

    return false unless ::File.exist?(receiver_inputs_conf_path)

    document = IniParse.parse(::File.read(receiver_inputs_conf_path))
    document.has_section?(receiver_stanza)
  end

  def write_receiver_port_config
    require 'fileutils'
    require 'iniparse'

    ::FileUtils.mkdir_p(::File.dirname(receiver_inputs_conf_path))
    document = IniParse.parse(::File.exist?(receiver_inputs_conf_path) ? ::File.read(receiver_inputs_conf_path) : '')
    document.section(receiver_stanza)['disabled'] = '0' unless document.has_section?(receiver_stanza)
    document.save(receiver_inputs_conf_path)
  end

  def receiver_inputs_conf_path
    "#{new_resource.install_dir}/etc/system/local/inputs.conf"
  end

  def receiver_stanza
    "splunktcp://#{new_resource.receiver_port}"
  end
end
