# splunk_monitor

The `splunk_monitor` resource manages Splunk monitor input stanzas in `inputs.conf`.

## Actions

- `:create`: Creates or updates a monitor stanza.
- `:remove`: Removes a monitor stanza.

## Properties

- `monitor_name`: The path to monitor. Default is the name of the resource. Prepends `monitor://` if missing.
- `inputs_conf_path`: The path to `inputs.conf`. Required.
- `host`: Host for the monitor stanza.
- `index`: Index for the monitor stanza.
- `sourcetype`: Source type for the monitor stanza.
- `queue`: Splunk queue.
- `source`: Source for the monitor stanza.
- `whitelist`: Whitelist regex.
- `blacklist`: Blacklist regex.
- `recursive`: Whether to monitor recursively. Default `true`.
- `followSymlink`: Whether to follow symlinks. Default `true`.

## Examples

```ruby
splunk_monitor '/var/log/syslog' do
  inputs_conf_path '/opt/splunkforwarder/etc/system/local/inputs.conf'
  sourcetype 'syslog'
  index 'main'
end
```
