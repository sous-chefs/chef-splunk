# frozen_string_literal: true

provides :splunk_server
unified_mode true

property :instance_name, String, name_property: true
property :install_dir, String, default: '/opt/splunk'
property :package_name, String, default: 'splunk'
property :url, String, required: true
property :version, String
property :mgmt_port, Integer, default: 8089
property :receiver_port, Integer, default: 9997
property :web_port, Integer, default: 443
property :runas_user, String, default: 'splunk'
property :splunk_auth, String, sensitive: true, required: true

action :install do
  splunk_installer new_resource.package_name do
    url new_resource.url
    version new_resource.version if new_resource.version
  end

  execute 'update-splunk-mgmt-port' do
    command mgmt_port_command
    sensitive true
    environment(
      'SPLUNK_USER' => auth_user,
      'SPLUNK_PASSWORD' => auth_password
    )
  end

  execute 'update-splunk-receiver-port' do
    command receiver_port_command
    sensitive true
    environment(
      'SPLUNK_USER' => auth_user,
      'SPLUNK_PASSWORD' => auth_password
    )
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
  def auth_user
    new_resource.splunk_auth.split(':')[0]
  end

  def auth_password
    new_resource.splunk_auth.split(':')[1]
  end

  def splunk_cmd(args)
    cmd = "#{new_resource.install_dir}/bin/splunk #{args}"
    return cmd if new_resource.runas_user == 'root'
    "su - #{new_resource.runas_user} -c '#{cmd}'"
  end

  def mgmt_port_command
    splunk_cmd("set splunkd-port #{new_resource.mgmt_port} -auth '#{new_resource.splunk_auth}'")
  end

  def receiver_port_command
    splunk_cmd("enable listen #{new_resource.receiver_port} -auth '#{new_resource.splunk_auth}'")
  end
end
