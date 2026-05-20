# frozen_string_literal: true

name              'chef-splunk'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Manage Splunk Enterprise or Splunk Universal Forwarder'
version           '10.0.0'
source_url        'https://github.com/sous-chefs/chef-splunk'
issues_url        'https://github.com/sous-chefs/chef-splunk/issues'
chef_version      '>= 16.0'

supports 'almalinux', '>= 9.0'
supports 'amazon', '>= 2023.0'
supports 'debian', '>= 12.0'
supports 'opensuseleap', '>= 16.0'
supports 'redhat', '>= 9.0'
supports 'rocky', '>= 9.0'
supports 'ubuntu', '>= 22.04'
