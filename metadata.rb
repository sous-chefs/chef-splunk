name 'chef-splunk'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Manage Splunk Enterprise or Splunk Universal Forwarder'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.6.0'

# for secrets management in setup_auth recipe
depends 'chef-vault', '>= 1.0.4'

source_url 'https://github.com/chef-cookbooks/chef-splunk' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/chef-splunk/issues' if respond_to?(:issues_url)

chef_version '>= 11' if respond_to?(:chef_version)
