name              'chef-splunk'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Manage Splunk Enterprise or Splunk Universal Forwarder'
version           '7.1.0'
source_url        'https://github.com/sous-chefs/chef-splunk'
issues_url        'https://github.com/sous-chefs/chef-splunk/issues'
chef_version      '>= 13.11'

# pins are temporary
supports 'amazon'
supports 'centos', '>= 7.0'
supports 'debian', '>= 9.0'
supports 'redhat'
supports 'ubuntu', '>= 18.04'

# please read the README.md section regarding data bag fallback if you
# do not use chef-vault
depends 'apt'
depends 'chef-vault', '~> 4.0'
depends 'ec2-tags-ohai-plugin', '~> 0.2.4'
