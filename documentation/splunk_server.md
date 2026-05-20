# splunk_server

Installs Splunk Enterprise and configures management and receiver ports.

## Actions

| Action     | Description                                   | Default |
|------------|-----------------------------------------------|---------|
| `:install` | Install Splunk Enterprise and configure ports | Yes     |
| `:remove`  | Remove the Splunk Enterprise package          |         |

## Properties

| Property        | Type    | Default       | Description                         |
|-----------------|---------|---------------|-------------------------------------|
| `instance_name` | String  | Resource name | Name of this server instance        |
| `install_dir`   | String  | `/opt/splunk` | Splunk installation directory       |
| `package_name`  | String  | `splunk`      | Package name                        |
| `url`           | String  | **Required**  | Download URL for the Splunk package |
| `version`       | String  |               | Package version                     |
| `mgmt_port`     | Integer | `8089`        | Management port                     |
| `receiver_port` | Integer | `9997`        | Receiver port for indexing          |
| `web_port`      | Integer | `443`         | Web UI port                         |
| `runas_user`    | String  | `splunk`      | User to run Splunk commands as      |
| `splunk_auth`   | String  | **Required**  | Authentication string (user:pass)   |

## Examples

### Install Splunk Enterprise

```ruby
splunk_server 'default' do
  url 'https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-amd64.deb'
  splunk_auth 'admin:changeme'
end
```

### Install with custom ports

```ruby
splunk_server 'default' do
  url 'https://download.splunk.com/products/splunk/releases/10.0.5/linux/splunk-10.0.5-3d2e2618f448-linux-amd64.deb'
  splunk_auth 'admin:changeme'
  mgmt_port 9089
  receiver_port 19997
  runas_user 'root'
end
```
