# splunk_auth

Manages Splunk admin authentication by creating the `user-seed.conf` file.

## Actions

| Action    | Description                        | Default |
| --------- | ---------------------------------- | ------- |
| `:create` | Create the user-seed.conf file     | Yes     |
| `:remove` | Delete the user-seed.conf file     |         |

## Properties

| Property         | Type   | Default       | Description                         |
| ---------------- | ------ | ------------- | ----------------------------------- |
| `instance_name`  | String | Resource name | Name of this auth instance          |
| `install_dir`    | String | `/opt/splunk` | Splunk installation directory       |
| `admin_user`     | String | `admin`       | Admin username                      |
| `admin_password` | String | **Required**  | Admin password (hashed or cleartext)|

## Examples

### Set admin password

```ruby
splunk_auth 'admin' do
  install_dir '/opt/splunk'
  admin_password 'notarealpassword'
end
```

### Set custom admin user

```ruby
splunk_auth 'custom' do
  install_dir '/opt/splunk'
  admin_user 'myadmin'
  admin_password 'secretpass'
end
```
