# splunk_installer

The `splunk_installer` resource installs or upgrades Splunk Enterprise or Splunk Universal Forwarder from a remote URL.

## Actions

- `:run`: Installs Splunk if not already installed.
- `:upgrade`: Upgrades Splunk if already installed.
- `:remove`: Removes Splunk installation, user, group, and configuration files.

## Properties

- `package_name`: The name of the package to install. Default is the name of the resource.
- `url`: The URL to download the package from.
- `version`: The version of Splunk to install.
- `runas_user`: The system user that runs Splunk. Default is `'splunk'`.

## Examples

```ruby
splunk_installer 'splunkforwarder' do
  url 'https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-arm64.deb'
  version '9.4.0'
end
```
