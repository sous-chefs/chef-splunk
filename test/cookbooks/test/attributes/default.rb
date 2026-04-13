# frozen_string_literal: true

# Splunk 10.x ARM64 support:
# - Universal Forwarder 10.0+ has native ARM64 .deb, .rpm, and .tgz
# - Splunk Enterprise (server) has NO ARM64 packages at all
# Server suites will fail on ARM64 — skip them locally.

arm64 = node['kernel']['machine'] == 'aarch64'
deb_arch = arm64 ? 'arm64' : 'amd64'
rpm_arch = arm64 ? 'aarch64' : 'x86_64'

default['test']['forwarder_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => "https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448.#{rpm_arch}.rpm",
  'debian' => "https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-#{deb_arch}.deb"
)

default['test']['server_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => "https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448.#{rpm_arch}.rpm",
  'debian' => "https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-#{deb_arch}.deb"
)

default['test']['upgrade_forwarder_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => "https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b.#{rpm_arch}.rpm",
  'debian' => "https://download.splunk.com/products/universalforwarder/releases/10.0.1/linux/splunkforwarder-10.0.1-c486717c322b-linux-#{deb_arch}.deb"
)

default['test']['upgrade_server_url'] = value_for_platform_family(
  %w(rhel fedora suse amazon) => "https://download.splunk.com/products/splunk/releases/10.0.1/linux/splunk-10.0.1-c486717c322b.#{rpm_arch}.rpm",
  'debian' => "https://download.splunk.com/products/splunk/releases/10.0.1/linux/splunk-10.0.1-c486717c322b-linux-#{deb_arch}.deb"
)
