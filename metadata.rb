name              'chef-splunk'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Manage Splunk Enterprise or Splunk Universal Forwarder'
version           '9.2.16'
source_url        'https://github.com/sous-chefs/chef-splunk'
issues_url        'https://github.com/sous-chefs/chef-splunk/issues'
chef_version      '>= 16.0'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'redhat'
supports 'ubuntu'
supports 'suse'

# please read the README.md section regarding data bag fallback if you
# do not use chef-vault
depends 'ec2-tags-ohai-plugin', '>= 0.2.4'
