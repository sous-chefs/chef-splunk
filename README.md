# chef-splunk Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/chef-splunk.svg)](https://supermarket.chef.io/cookbooks/chef-splunk)
[![CI State](https://github.com/sous-chefs/chef-splunk/workflows/ci/badge.svg)](https://github.com/sous-chefs/chef-splunk/actions?query=workflow%3Aci)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

This cookbook provides custom resources for managing Splunk Enterprise and Splunk Universal Forwarder.

## Requirements

Chef Infra Client 16.0 or newer.

## Migration

Version 10.0 removes the public recipe and node attribute API. See [migration.md](migration.md) for the breaking change details and examples.

## Platforms

The supported platform list follows Splunk 10.0 package availability and this cookbook's Kitchen matrix:

* AlmaLinux 9, 10
* Amazon Linux 2023
* Debian 12, 13
* Red Hat Enterprise Linux 9, 10
* Rocky Linux 9, 10
* Ubuntu 22.04, 24.04
* openSUSE Leap 16

See [LIMITATIONS.md](LIMITATIONS.md) for platform and architecture notes.

## Resources

* [splunk_app](documentation/splunk_app.md)
* [splunk_auth](documentation/splunk_auth.md)
* [splunk_client](documentation/splunk_client.md)
* [splunk_clustering](documentation/splunk_clustering.md)
* [splunk_index](documentation/splunk_index.md)
* [splunk_installer](documentation/splunk_installer.md)
* [splunk_monitor](documentation/splunk_monitor.md)
* [splunk_server](documentation/splunk_server.md)
* [splunk_service](documentation/splunk_service.md)
* [splunk_shclustering](documentation/splunk_shclustering.md)
* [splunk_ssl](documentation/splunk_ssl.md)
* [splunk_user](documentation/splunk_user.md)

## Examples

Install and configure a Universal Forwarder:

```ruby
splunk_client 'default' do
  accept_license true
  auth 'admin:changeme'
  server_list ['splunk.example.com:9997']
end
```

Install and configure a Splunk Enterprise server:

```ruby
splunk_server 'default' do
  accept_license true
  auth 'admin:changeme'
  receiver_port '9997'
  web_port '8000'
end
```

Add a monitor stanza:

```ruby
splunk_monitor '/var/log/messages' do
  inputs_conf_path '/opt/splunkforwarder/etc/apps/SplunkUniversalForwarder/default/inputs.conf'
  sourcetype 'linux_messages_syslog'
  index 'os'
end
```

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks.
