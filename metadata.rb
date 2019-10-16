name 'chef-splunk'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Manage Splunk Enterprise or Splunk Universal Forwarder'
version '3.1.0'

supports 'debian', '>= 8.9'
supports 'ubuntu', '>= 16.04'
supports 'redhat', '>= 6.9'
supports 'centos', '>= 6.9'

# for secrets management in setup_auth recipe
depends 'chef-vault', '>= 3.1.1'

source_url 'https://github.com/chef-cookbooks/chef-splunk'
issues_url 'https://github.com/chef-cookbooks/chef-splunk/issues'
chef_version '>= 13.11'
