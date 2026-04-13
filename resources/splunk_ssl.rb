# frozen_string_literal: true

provides :splunk_ssl
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunk'
property :keyfile_path, String, default: lazy { "#{install_dir}/etc/auth/certs/splunk.key" }
property :crtfile_path, String, default: lazy { "#{install_dir}/etc/auth/certs/splunk.crt" }
property :keyfile_content, String, sensitive: true, required: true
property :crtfile_content, String, required: true
property :web_port, Integer, default: 443
property :mgmt_port, Integer, default: 8089
property :enable_ssl, [true, false], default: true

action :create do
  directory ::File.dirname(new_resource.keyfile_path) do
    recursive true
  end

  file new_resource.keyfile_path do
    content new_resource.keyfile_content
    sensitive true
    mode '0600'
  end

  file new_resource.crtfile_path do
    content new_resource.crtfile_content
    mode '0644'
  end

  template "#{new_resource.install_dir}/etc/system/local/web.conf" do
    source 'web.conf.erb'
    cookbook 'chef-splunk'
    variables(
      web_port: new_resource.web_port,
      mgmt_port: new_resource.mgmt_port,
      enable_ssl: new_resource.enable_ssl,
      keyfile_path: new_resource.keyfile_path,
      crtfile_path: new_resource.crtfile_path
    )
  end
end

action :remove do
  file new_resource.keyfile_path do
    action :delete
  end

  file new_resource.crtfile_path do
    action :delete
  end

  file "#{new_resource.install_dir}/etc/system/local/web.conf" do
    action :delete
  end
end
