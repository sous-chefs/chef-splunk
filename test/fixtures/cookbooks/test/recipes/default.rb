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
