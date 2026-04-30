# splunk_user

Manages the Splunk system user and group.

## Actions

| Action    | Description                      | Default |
|-----------|----------------------------------|---------|
| `:create` | Create the Splunk user and group | Yes     |
| `:remove` | Remove the Splunk user and group |         |

## Properties

| Property   | Type    | Default           | Description                  |
|------------|---------|-------------------|------------------------------|
| `username` | String  | Resource name     | Username for the Splunk user |
| `uid`      | Integer | `396`             | UID for the Splunk user      |
| `gid`      | Integer | `396`             | GID for the Splunk group     |
| `comment`  | String  | `Splunk Server`   | Comment field for the user   |
| `home`     | String  | `/opt/<username>` | Home directory for the user  |
| `shell`    | String  | `/bin/bash`       | Login shell for the user     |

## Examples

### Create default Splunk user

```ruby
splunk_user 'splunk'
```

### Create user with custom settings

```ruby
splunk_user 'splunk' do
  uid 500
  gid 500
  home '/opt/splunk'
  shell '/sbin/nologin'
end
```

### Remove Splunk user

```ruby
splunk_user 'splunk' do
  action :remove
end
```
