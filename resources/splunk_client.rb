# frozen_string_literal: true

provides :splunk_client
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunkforwarder'
property :package_name, String, default: 'splunkforwarder'
property :url, String, required: true
property :version, String
property :server_list, String, required: true
property :receiver_port, Integer, default: 9997
property :outputs_conf, Hash, default: {}

action :install do
  splunk_installer new_resource.package_name do
    url new_resource.url
    version new_resource.version if new_resource.version
  end

  directory "#{new_resource.install_dir}/etc/system/local" do
    recursive true
    owner new_resource.runas_user
    group new_resource.runas_user
  end

  template "#{new_resource.install_dir}/etc/system/local/outputs.conf" do
    source 'client_outputs.conf.erb'
    cookbook 'chef-splunk'
    mode '644'
    owner new_resource.runas_user
    group new_resource.runas_user
    variables(
      server_list: new_resource.server_list,
      receiver_port: new_resource.receiver_port,
      outputs_conf: new_resource.outputs_conf
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
