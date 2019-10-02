apt_update 'update' if platform_family?('debian')

if platform_family?('rhel')
  node.force_default['yum']['base']['gpgkey'] = \
    "https://www.centos.org/keys/RPM-GPG-KEY-CentOS-#{node['platform_version'].to_i}"
  node.force_default['yum']['updates']['gpgkey'] = \
    "https://www.centos.org/keys/RPM-GPG-KEY-CentOS-#{node['platform_version'].to_i}"
  node.force_default['yum']['base']['fastestmirror_enabled'] = true
  node.force_default['yum']['updates']['fastestmirror_enabled'] = true
  include_recipe 'yum-centos'
end

splunk_app 'bistro' do
  splunk_auth 'admin:notarealpassword'
  cookbook_file 'bistro-1.0.2.spl'
  checksum '862e2c4422eee93dd50bd93aa73a44045d02cb6232f971ba390a2f1c15bdb79f'
  action %i(install enable)
end

splunk_app 'bistro-disable' do
  app_name 'bistro'
  splunk_auth 'admin:notarealpassword'
  action %i(disable remove)
end

splunk_app 'sanitycheck' do
  remote_directory 'sanitycheck'
  splunk_auth 'admin:notarealpassword'
  action :install
end

splunk_app 'bistro-remote-file' do
  app_name 'bistro-1.0.2'
  remote_file 'https://github.com/ampledata/bistro/archive/1.0.2.tar.gz'
  splunk_auth 'admin:notarealpassword'
  templates %w(inputs.conf)
  app_dependencies(%w(ruby))
  action :install
end
