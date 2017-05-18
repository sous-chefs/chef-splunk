name 'chef-splunk'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Manage Splunk Enterprise or Splunk Universal Forwarder'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.6.0'

supports 'debian'
supports 'ubuntu'
supports 'redhat'
supports 'centos'

# for secrets management in setup_auth recipe
depends 'chef-vault', '>= 1.0.4'

source_url 'https://github.com/chef-cookbooks/chef-splunk'
issues_url 'https://github.com/chef-cookbooks/chef-splunk/issues'
chef_version '>= 12.1' if respond_to?(:chef_version)
