# splunk_index

The `splunk_index` resource manages Splunk index stanzas in `indexes.conf`.

## Actions

- `:create`: Creates or updates an index stanza.
- `:remove`: Removes an index stanza.

## Properties

- `index_name`: The name of the index. Default is the name of the resource.
- `indexes_conf_path`: The path to `indexes.conf`. Required.
- `options`: A Hash of options for the index stanza.
- `backup`: Number of backups to keep for the configuration file.

## Examples

```ruby
splunk_index 'my_index' do
  indexes_conf_path '/opt/splunk/etc/system/local/indexes.conf'
  options({
    'maxTotalDataSizeMB' => 512000,
    'frozenTimePeriodInSecs' => 7776000,
  })
end
```
