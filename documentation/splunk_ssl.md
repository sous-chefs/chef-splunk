# splunk_ssl

Configures SSL for Splunk Web by managing certificates and `web.conf`.

## Actions

| Action    | Description                                    | Default |
| --------- | ---------------------------------------------- | ------- |
| `:create` | Create SSL certificates and web.conf           | Yes     |
| `:remove` | Delete SSL certificates and web.conf           |         |

## Properties

| Property          | Type    | Default                                    | Description                    |
| ----------------- | ------- | ------------------------------------------ | ------------------------------ |
| `instance_name`   | String  | Resource name                              | Name of this SSL instance      |
| `install_dir`     | String  | `/opt/splunk`                              | Splunk installation directory  |
| `keyfile_path`    | String  | `<install_dir>/etc/auth/certs/splunk.key`  | Path for the private key       |
| `crtfile_path`    | String  | `<install_dir>/etc/auth/certs/splunk.crt`  | Path for the certificate       |
| `keyfile_content` | String  | **Required**                               | Private key content            |
| `crtfile_content` | String  | **Required**                               | Certificate content            |
| `web_port`        | Integer | `443`                                      | Splunk Web port                |
| `mgmt_port`       | Integer | `8089`                                     | Management port                |
| `enable_ssl`      | Boolean | `true`                                     | Enable SSL for Splunk Web      |

## Examples

### Configure SSL with default paths

```ruby
splunk_ssl 'default' do
  install_dir '/opt/splunk'
  keyfile_content 'PRIVATE KEY CONTENT'
  crtfile_content 'CERTIFICATE CONTENT'
end
```

### Configure SSL with custom certificate paths

```ruby
splunk_ssl 'custom' do
  install_dir '/opt/splunk'
  keyfile_path '/opt/splunk/etc/auth/custom.key'
  crtfile_path '/opt/splunk/etc/auth/custom.crt'
  keyfile_content 'PRIVATE KEY CONTENT'
  crtfile_content 'CERTIFICATE CONTENT'
  web_port 8443
end
```
