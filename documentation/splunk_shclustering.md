# splunk_shclustering

Configures Splunk search head clustering (deployer, member, or captain mode).

## Actions

| Action    | Description                                  | Default |
| --------- | -------------------------------------------- | ------- |
| `:create` | Configure search head cluster membership     | Yes     |

## Properties

| Property              | Type    | Default                                            | Description                                  |
| --------------------- | ------- | -------------------------------------------------- | -------------------------------------------- |
| `instance_name`       | String  | Resource name                                      | Name of this shclustering instance           |
| `install_dir`         | String  | `/opt/splunk`                                      | Splunk installation directory                |
| `mode`                | String  | **Required**                                       | Mode: `deployer`, `member`, `captain`        |
| `label`               | String  | **Required**                                       | Search head cluster label                    |
| `replication_factor`  | Integer | `3`                                                | Replication factor                           |
| `replication_port`    | Integer | `34567`                                            | Replication port                             |
| `mgmt_uri`            | String  |                                                    | Management URI for this node                 |
| `deployer_url`        | String  |                                                    | URL of the search head deployer              |
| `secret`              | String  |                                                    | Shared cluster secret                        |
| `splunk_auth`         | String  |                                                    | Authentication string (member/captain mode)  |
| `runas_user`          | String  | `splunk`                                           | User to run Splunk as                        |
| `app_dir`             | String  | `<install_dir>/etc/apps/0_PC_shcluster_config`     | App directory for deployer config            |
| `shcluster_members`   | Array   | `[]`                                               | Static list of cluster member URIs           |

## Examples

### Configure search head deployer

```ruby
splunk_shclustering 'default' do
  mode 'deployer'
  label 'shcluster1'
  secret 'shcluster_secret'
end
```

### Configure search head cluster member

```ruby
splunk_shclustering 'default' do
  mode 'member'
  mgmt_uri 'https://shmember1:8089'
  replication_port 34567
  replication_factor 3
  deployer_url 'https://deployer:8089'
  label 'shcluster1'
  secret 'shcluster_secret'
  splunk_auth 'admin:changeme'
end
```
