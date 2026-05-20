# splunk_service

Manages the Splunk systemd service, including directory permissions, boot-start configuration, and service lifecycle.

## Actions

| Action     | Description                                  | Default |
|------------|----------------------------------------------|---------|
| `:start`   | Create directories, enable boot-start, start | Yes     |
| `:stop`    | Stop and disable the service                 |         |
| `:restart` | Restart the service                          |         |

## Properties

| Property         | Type    | Default                | Description                   |
|------------------|---------|------------------------|-------------------------------|
| `instance_name`  | String  | Resource name          | Name of this service instance |
| `install_dir`    | String  | `/opt/splunkforwarder` | Splunk installation directory |
| `runas_user`     | String  | `splunk`               | User to run Splunk as         |
| `service_name`   | String  | `SplunkForwarder`      | Systemd service name          |
| `accept_license` | Boolean | `true`                 | Accept the Splunk license     |

## Examples

### Start Splunk Forwarder service

```ruby
splunk_service 'splunk' do
  install_dir '/opt/splunkforwarder'
  service_name 'SplunkForwarder'
  runas_user 'splunk'
end
```

### Start Splunk Enterprise service

```ruby
splunk_service 'splunk' do
  install_dir '/opt/splunk'
  service_name 'Splunkd'
  runas_user 'splunk'
end
```

### Stop and disable the service

```ruby
splunk_service 'splunk' do
  install_dir '/opt/splunk'
  service_name 'Splunkd'
  action :stop
end
```
