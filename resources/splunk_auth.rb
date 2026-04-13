# frozen_string_literal: true

provides :splunk_auth
unified_mode true

use 'splunk_instance'
property :install_dir, String, default: '/opt/splunk'
property :admin_user, String, default: 'admin'
property :admin_password, String, sensitive: true, required: true

action :create do
  directory "#{new_resource.install_dir}/etc/system/local" do
    recursive true
  end

  file 'user-seed.conf' do
    path "#{new_resource.install_dir}/etc/system/local/user-seed.conf"
    content "[user_info]\nUSERNAME = #{new_resource.admin_user}\nHASHED_PASSWORD = #{new_resource.admin_password}\n"
    sensitive true
  end
end

action :remove do
  file 'user-seed.conf' do
    path "#{new_resource.install_dir}/etc/system/local/user-seed.conf"
    action :delete
  end
end
