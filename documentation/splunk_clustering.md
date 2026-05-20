# splunk_clustering

Configures Splunk indexer clustering (master, slave, or searchhead mode).

## Actions

| Action    | Description                             | Default |
| --------- | --------------------------------------- | ------- |
| `:create` | Configure indexer cluster membership    | Yes     |

## Properties

| Property                  | Type    | Default       | Description                                    |
| ------------------------- | ------- | ------------- | ---------------------------------------------- |
| `instance_name`           | String  | Resource name | Name of this clustering instance               |
| `install_dir`             | String  | `/opt/splunk` | Splunk installation directory                  |
| `mode`                    | String  | **Required**  | Cluster mode: `master`, `slave`, `searchhead`  |
| `replication_factor`      | Integer | `3`           | Replication factor (master mode)               |
| `search_factor`           | Integer | `2`           | Search factor (master mode)                    |
| `replication_port`        | Integer | `9887`        | Replication port (slave/searchhead mode)       |
| `master_uri`              | String  |               | Master URI (slave/searchhead mode)             |
| `num_sites`               | Integer | `1`           | Number of sites (>1 enables multisite)         |
| `site`                    | String  |               | Site assignment (multisite mode)               |
| `site_replication_factor` | String  |               | Per-site replication factor (multisite mode)   |
| `site_search_factor`      | String  |               | Per-site search factor (multisite mode)        |
| `splunk_auth`             | String  | **Required**  | Authentication string (user:pass)              |
| `secret`                  | String  |               | Shared cluster secret                          |
| `runas_user`              | String  | `splunk`      | User to run Splunk commands as                 |

## Examples

### Configure cluster master

```ruby
splunk_clustering 'default' do
  mode 'master'
  replication_factor 3
  search_factor 2
  splunk_auth 'admin:changeme'
end
```

### Configure cluster slave

```ruby
splunk_clustering 'default' do
  mode 'slave'
  master_uri 'https://master:8089'
  replication_port 9887
  splunk_auth 'admin:changeme'
end
```

### Configure multisite cluster master

```ruby
splunk_clustering 'default' do
  mode 'master'
  num_sites 2
  site 'site1'
  site_replication_factor 'origin:2,total:3'
  site_search_factor 'origin:1,total:2'
  splunk_auth 'admin:changeme'
end
```
