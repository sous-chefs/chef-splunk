name             'chef-splunk'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@getchef.com'
license          'Apache 2.0'
description      'Manage Splunk Enterprise or Splunk Universal Forwarder'
version          '1.2.0'

# for secrets management in setup_auth recipe
depends 'chef-vault', '>= 1.0.4'
