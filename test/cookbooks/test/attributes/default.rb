# frozen_string_literal: true

default['test']['forwarder_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb'
)

default['test']['server_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/splunk/releases/9.4.0/linux/splunk-9.4.0-6b4ebe426ca6-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/splunk/releases/9.4.0/linux/splunk-9.4.0-6b4ebe426ca6-linux-amd64.deb'
)

default['test']['upgrade_forwarder_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
)

default['test']['upgrade_server_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
  'debian' => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
)
