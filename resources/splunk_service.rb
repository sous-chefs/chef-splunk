# frozen_string_literal: true

provides :splunk_service
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunkforwarder'
property :service_name, String, default: 'SplunkForwarder'
property :accept_license, [true, false], default: true
property :admin_user, String, default: 'admin'
property :admin_password, String, sensitive: true
property :optimistic_file_locking, [true, false], default: false

action :start do
  directory new_resource.install_dir do
    owner new_resource.runas_user
    group new_resource.runas_user
    mode '755'
  end

  execute "chown #{new_resource.install_dir}" do
    command "chown -R #{new_resource.runas_user}:#{new_resource.runas_user} #{new_resource.install_dir}"
    only_if { new_resource.runas_user != 'root' && ::File.exist?("#{new_resource.install_dir}/bin/splunk") }
    not_if { install_owned_by_runas_user? }
  end

  %w(var var/log var/log/splunk).each do |subdir|
    dir_mode = subdir == 'var/log/splunk' ? '700' : '711'
    directory "#{new_resource.install_dir}/#{subdir}" do
      owner new_resource.runas_user
      group new_resource.runas_user
      mode dir_mode
    end
  end

  ruby_block 'enable optimistic file locking' do
    block do
      launch_conf = "#{new_resource.install_dir}/etc/splunk-launch.conf"
      line = 'OPTIMISTIC_ABOUT_FILE_LOCKING=1'
      content = ::File.exist?(launch_conf) ? ::File.read(launch_conf) : ''

      ::File.open(launch_conf, 'a') { |file| file.puts line } unless content.lines.any? { |entry| entry.strip == line }
    end
    only_if { new_resource.optimistic_file_locking }
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
  def install_owned_by_runas_user?
    require 'etc'

    uid = Etc.getpwnam(new_resource.runas_user).uid
    [new_resource.install_dir, "#{new_resource.install_dir}/bin/splunk"].all? do |path|
      ::File.exist?(path) && ::File.stat(path).uid == uid
    end
  rescue ArgumentError
    false
  end

  def boot_start_command
    seed_password = new_resource.admin_password ? ' --seed-passwd "$SPLUNK_PASSWORD" --answer-yes --no-prompt' : ''

    if new_resource.runas_user == 'root'
      "#{new_resource.install_dir}/bin/splunk enable boot-start -user root -systemd-managed 1 --accept-license#{seed_password}"
    else
      "#{new_resource.install_dir}/bin/splunk enable boot-start -user #{new_resource.runas_user} -systemd-managed 1 --accept-license#{seed_password}"
    end
  end
end
