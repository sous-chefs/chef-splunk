# frozen_string_literal: true

provides :splunk_service
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunkforwarder'
property :service_name, String, default: 'SplunkForwarder'
property :accept_license, [true, false], default: true
property :admin_user, String, default: 'admin'
property :admin_password, String, sensitive: true

action :start do
  directory new_resource.install_dir do
    owner new_resource.runas_user
    group new_resource.runas_user
    mode '755'
  end

  %w(var var/log var/log/splunk).each do |subdir|
    dir_mode = subdir == 'var/log/splunk' ? '700' : '711'
    directory "#{new_resource.install_dir}/#{subdir}" do
      owner new_resource.runas_user
      group new_resource.runas_user
      mode dir_mode
    end
  end

  execute 'splunk first run' do
    command "#{first_run_command} && touch #{new_resource.install_dir}/etc/.init_ok"
    sensitive true
    environment(
      'SPLUNK_USER' => new_resource.admin_user,
      'SPLUNK_PASSWORD' => new_resource.admin_password
    ) if new_resource.admin_password
    creates "#{new_resource.install_dir}/etc/.init_ok"
  end

  execute 'splunk enable boot-start' do
    command boot_start_command
    sensitive true
    environment(
      'SPLUNK_USER' => new_resource.admin_user,
      'SPLUNK_PASSWORD' => new_resource.admin_password
    ) if new_resource.admin_password
    retries 3
    not_if { ::File.exist?("/usr/lib/systemd/system/#{new_resource.service_name}.service") || ::File.exist?("/etc/systemd/system/#{new_resource.service_name}.service") }
  end

  # Splunk 10.x places the real unit file in /usr/lib/systemd/system/ and
  # creates a symlink in /etc/systemd/system/. systemd refuses to enable
  # alias/linked unit files, so remove the symlink (but only if it is a symlink).
  file "/etc/systemd/system/#{new_resource.service_name}.service" do
    action :delete
    only_if { ::File.symlink?("/etc/systemd/system/#{new_resource.service_name}.service") }
    notifies :run, 'execute[systemctl daemon-reload]', :immediately
  end

  execute 'systemctl daemon-reload' do
    action :nothing
  end

  service new_resource.service_name do
    action [:enable, :start]
    supports status: true, restart: true
  end
end

action :stop do
  service new_resource.service_name do
    action [:stop, :disable]
    supports status: true, restart: true
  end
end

action :restart do
  service new_resource.service_name do
    action :restart
    supports status: true, restart: true
  end
end

action_class do
  def first_run_command
    if new_resource.runas_user == 'root'
      "#{new_resource.install_dir}/bin/splunk start --accept-license --no-prompt --answer-yes && #{new_resource.install_dir}/bin/splunk stop"
    else
      "#{new_resource.install_dir}/bin/splunk start --accept-license --no-prompt --answer-yes -user #{new_resource.runas_user} && #{new_resource.install_dir}/bin/splunk stop"
    end
  end

  def boot_start_command
    if new_resource.runas_user == 'root'
      "#{new_resource.install_dir}/bin/splunk enable boot-start -systemd-managed 1 --accept-license"
    else
      "#{new_resource.install_dir}/bin/splunk enable boot-start -user #{new_resource.runas_user} -systemd-managed 1 --accept-license"
    end
  end
end
