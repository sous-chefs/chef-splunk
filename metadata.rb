name 'chef-splunk'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Manage Splunk Enterprise or Splunk Universal Forwarder'
version '7.0.2'

supports 'debian', '>= 8.9'
supports 'ubuntu', '>= 16.04'
supports 'redhat', '>= 6.9'
supports 'centos', '>= 6.9'
supports 'amazon'

# please read the README.md section regarding data bag fallback if you
# do not use chef-vault
depends 'chef-vault', '~> 4.0'

source_url 'https://github.com/chef-cookbooks/chef-splunk'
issues_url 'https://github.com/chef-cookbooks/chef-splunk/issues'
chef_version '>= 13.11'
