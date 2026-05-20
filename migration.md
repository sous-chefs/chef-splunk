# Migrating to Custom Resources

chef-splunk 10.0 removes the public recipe and node attribute API. Use the custom resources in this cookbook directly from wrapper cookbooks instead.

## What Changed

The root `recipes/` and `attributes/` directories have been removed. The cookbook now provides resources that model Splunk installation, configuration, service management, clustering, SSL, apps, indexes, and monitors.

Old run list usage such as:

```ruby
run_list 'recipe[chef-splunk::default]'
```

should become wrapper cookbook resource usage:

```ruby
splunk_client 'default' do
  accept_license true
  auth 'admin:changeme'
  server_list ['splunk.example.com:9997']
end
```

For Splunk Enterprise servers:

```ruby
splunk_server 'default' do
  accept_license true
  auth 'admin:changeme'
  receiver_port '9997'
  web_port '8000'
end
```

## Attribute Mapping

Move node attributes to resource properties in wrapper cookbooks.

| Former attribute | Resource property |
| --- | --- |
| `node['splunk']['accept_license']` | `accept_license` |
| `node['splunk']['data_bag']` | `data_bag` |
| `node['splunk']['disabled']` | `disabled` or `action :disable` |
| `node['splunk']['receiver_port']` | `receiver_port` |
| `node['splunk']['mgmt_port']` | `mgmt_port` |
| `node['splunk']['web_port']` | `web_port` |
| `node['splunk']['server_list']` | `server_list` |
| `node['splunk']['outputs_conf']` | `outputs_conf` |
| `node['splunk']['inputs_conf']` | `inputs_conf` |
| `node['splunk']['ssl_options']` | `splunk_ssl` properties |
| `node['splunk']['clustering']` | `splunk_clustering` properties |
| `node['splunk']['shclustering']` | `splunk_shclustering` properties |

## Test Cookbook Examples

Runnable examples live in `test/cookbooks/test/recipes/`:

* `default.rb`
* `client.rb`
* `server.rb`
* `disabled.rb`
* `client_resources.rb`
* `server_resources.rb`
* `upgrade_client.rb`
* `upgrade_server.rb`

Use those recipes as migration examples when converting wrapper cookbooks.
