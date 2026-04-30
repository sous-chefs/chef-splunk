# splunk_app

The `splunk_app` resource manages Splunk apps, including installation from cookbook files, remote files, or directories, and configuring them with templates.

## Actions

- `:install`: Installs and configures the Splunk app.
- `:remove`: Deletes the Splunk app directory.

## Properties

- `app_name`: The name of the app. Default is the name of the resource.
- `app_dependencies`: Array of package dependencies for the app.
- `app_dir`: The directory where the app is installed.
- `install_dir`: The Splunk installation directory. Default is `'/opt/splunk'`.
- `runas_user`: The system user that runs Splunk. Default is `'splunk'`.
- `cookbook`: The cookbook to find files/templates in.
- `cookbook_file`: The cookbook file to install.
- `remote_file`: The remote file to install.
- `local_file`: The local file to install.
- `remote_directory`: The remote directory to install.
- `templates`: Array or Hash of templates to configure the app.
- `template_variables`: Hash of variables for the templates.
- `files_mode`: The octal mode for files.

## Examples

```ruby
splunk_app 'my_app' do
  cookbook_file 'my_app.spl'
  templates ['inputs.conf', 'outputs.conf']
  template_variables({
    'inputs.conf' => { 'port' => 1234 },
  })
end
```
