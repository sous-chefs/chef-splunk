# splunk_client

Installs and configures a Splunk Universal Forwarder (client) with outputs.conf.

## Actions

| Action     | Description                                  | Default |
|------------|----------------------------------------------|---------|
| `:install` | Install forwarder and configure outputs.conf | Yes     |
| `:remove`  | Remove the forwarder package                 |         |

## Properties

| Property        | Type    | Default                | Description                                 |
|-----------------|---------|------------------------|---------------------------------------------|
| `instance_name` | String  | Resource name          | Name of this client instance                |
| `install_dir`   | String  | `/opt/splunkforwarder` | Splunk installation directory               |
| `package_name`  | String  | `splunkforwarder`      | Package name for the forwarder              |
| `url`           | String  | **Required**           | Download URL for the Splunk package         |
| `version`       | String  |                        | Package version                             |
| `server_list`   | String  | **Required**           | Comma-separated list of indexer servers     |
| `receiver_port` | Integer | `9997`                 | Receiver port for outputs.conf              |
| `runas_user`    | String  | `splunk`               | User to own configuration files             |
| `outputs_conf`  | Hash    | `{}`                   | Additional key-value pairs for outputs.conf |

## Examples

### Install forwarder with server list

```ruby
splunk_client 'default' do
  url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
  server_list 'indexer1:9997, indexer2:9997'
end
```

### Install with custom outputs.conf settings

```ruby
splunk_client 'default' do
  url 'https://download.splunk.com/products/universalforwarder/releases/10.0.5/linux/splunkforwarder-10.0.5-3d2e2618f448-linux-amd64.deb'
  server_list 'indexer1:9997'
  outputs_conf(
    'sslCertPath' => '$SPLUNK_HOME/etc/certs/cert.pem',
    'sslPassword' => 'password'
  )
end
```
