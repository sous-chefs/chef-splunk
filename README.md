chef-splunk Cookbook
====================

[![Build Status](https://travis-ci.org/chef-cookbooks/chef-splunk.svg?branch=master)](https://travis-ci.org/chef-cookbooks/chef-splunk)
[![Cookbook Version](https://img.shields.io/cookbook/v/chef-splunk.svg)](https://supermarket.chef.io/cookbooks/chef-splunk)

This cookbook manages a Splunk Universal Forwarder (client) or a
Splunk Enterprise (server) installation, including a Splunk clustered
environment.

The Splunk default user is admin and the password is changeme. See the
`setup_auth` recipe below for more information about how to manage
changing the password with Chef and Chef Vault.

This recipe downloads packages from Splunk directly. There are
attributes to set a URL to retrieve the packages, so if the packages
are mirrored locally, supply the local URL instead. At this time the
cookbook doesn't support installing from networked package managers
(like apt or yum), since Splunk doesn't provide package repositories.


## Requirements

Chef 13.11 or newer


## License Acceptance
In the past, it was sufficient to set the `node['splunk']['accept_license']` attribute
either in a wrapper cookbook, role, or chef environment, and the recipes in this cookbook
would enable and run the splunk service with `--accept-license`. Starting with version 3.0.0,
this attribute must be set to boolean `true`. A value resulting in anything other than boolean true will
be considered as not accepting the Splunk EULA.

For example, these will not accept the Splunk license:
```
node['splunk']['accept_license'] = false
node['splunk'] = { 'accept_license' => nil }
node['splunk']['accept_license'] = ''
node['splunk']['accept_license'] = 'true'
```

Only this will accept the license:
```
node['splunk']['accept_license'] = true
```

### Platforms

This cookbook uses Test Kitchen to do cross-platform convergence and
post-convergence tests. The tested platforms are considered supported.
This cookbook may work on other platforms or platform versions with or
without modification.

* Debian 8, 9
* Ubuntu 16.04, 18.04
* CentOS 6, 7
* Redhat 6, 7

By default, only 64-bit Splunk server and Splunk Universal Forwarder will be installed or upgraded by this cookbook.


### Cookbooks

Used for managing secrets, see __Usage__:

* chef-vault, `~> 4.0`


## Attributes

Attributes have default values set in `attributes/default.rb`. Where
possible or appropriate, the default values from Splunk Enterprise are
used.

General attributes:

* `node['splunk']['accept_license']`: Whether to accept the Splunk
  EULA. Default is false. This *must* be set to boolean true for Splunk to be
  functional with this cookbook, which means end users must read the
  EULA and agree to the terms.
* `node['splunk']['is_server']`: Set this to true if the node is a
  splunk server, for example in a role (Default: false)
* `node['splunk']['data_bag']`: Set this to the name of the data bag where your splunk auth
  and other secrets are stored (Default: `vault`)
* `node['splunk']['disabled']`: Disable the splunk agent by setting
  this to true (Default: false)
* `node['splunk']['receiver_port']`: The port that the receiver
  (server) listens to. This is set to the Splunk Enterprise default, 9997.
* `node['splunk']['mgmt_port']`: The port that splunkd service
  listens to, aka the management port. This is set to the Splunk
  Enterprise default, 8089.
* `node['splunk']['web_port']`: The port that the splunkweb service
  listens to. This is set to the default for HTTPS, 443, as it is
  configured by the `setup_ssl` recipe.
* `node['splunk']['ratelimit_kilobytessec']`: The default splunk rate limiting rate can now easily be changed with an attribute.  Default is 2048KBytes/sec.

The two URL attributes below are selected by platform and architecture
by default.

* `node['splunk']['forwarder']['url']`: The URL to the Splunk Universal Forwarder package file.
* `node['splunk']['server']['url']`: The URL to the Splunk Enterprise package file.
* `node['splunk']['forwarder']['version']`: specifies the splunk universal forwarder version to install. This is ignored if forwarder URL is provided. (Default: 8.0.1)
* `node['splunk']['server']['version']`: specifies the splunk server version to install. This is ignored if server URL is provided. (Default: 8.0.1)
* Set these attributes to `nil` or empty string `''` to force installing the packages from the
  OS package managers. In doing so, server owners are responsible for properly configuring their
  package manager so chef can install the package.

  For example, each line below will force the chef-client to install Splunk's Universal Forwarder
  and server from the local package manager:
  ```
  node.force_default['splunk']['forwarder']['url'] = ''
  node.force_default['splunk']['server']['url'] = ''
  node.force_default['splunk']['forwarder']['url'] = nil
  node.force_default['splunk']['server']['url'] = nil
  ```


Special attributes for managing the Splunk user:

* `node['splunk']['user']`: A hash of attributes to set for the splunk
  user resource in the `user` recipe. It's unlikely that someone would
  need to change these, other than the UID, but just in case...

- `username`: the username
- `comment`: gecos field
- `home`: the home directory, defaults to `/opt/splunkforwarder`, will
  be set to `/opt/splunk` if `node['splunk']['is_server']` is true.
- `shell`: the shell to use
- `uid`: the numeric UID. The default, `396` is an integer arbitrarily
  chosen and doesn't conflict with anything on the supported platforms
  (see list above). It is within the `system` UID range on Linux
  systems.

* `node['splunk']['server']['runasroot']`: if runasroot is true (which is the splunk upstream package default) then the splunk server runs as root.  If runasroot is false modify the init script to run as the `node['splunk']['user']`.  This does not apply to the splunk client as they may need root permissions to read logfiles.  NOTE1: you may also need to change `node['splunk']['web_port']` on a splunk server to run on a port >1024 if you don't run as root (splunk user cannot bind to privelaged ports).  NOTE2: If you want to switch from root to the splunk user or vice versa on an existing install, please stop the splunk service first before changing the runasroot boolean value.

The following attributes are related to setting up `splunkweb` with
SSL in the `setup_ssl` recipe.

* `node['splunk']['ssl_options']`: A hash of SSL options used in the
  `setup_ssl` recipe
* `node['splunk']['ssl_options']['enable_ssl']`: Whether to enable
  SSL, must be set to `true` to use the `setup_ssl` recipe. Defaults
  to `false`, must be set using a boolean literal `true` or `false`.
* `node['splunk']['ssl_options']['data_bag']`: The data bag name to
  load, defaults to `vault` (as chef-vault is used).
* `node['splunk']['ssl_options']['data_bag_item']`: The data bag item
  name that contains the keyfile and crtfile, defaults to
  `splunk_certificates`.
* `node['splunk']['ssl_options']['keyfile']`: The name of the SSL key
  file, and the content will be written to
  `etc/auth/splunkweb/KEYFILE`. Must be an element under `data` in the
  data bag item. See __Usage__ for instructions. Defaults to
  '`self-signed.example.com.key`', and should be changed to something
  relevant for the local site before use, in a role or wrapper cookbook.
* `node['splunk']['ssl_options']['crtfile']`: The name of the SSL cert
  (crt) file, and the content will be written to
  `/etc/auth/splunkweb/CRTFILE`. Must be an element under `data` in
  the data bag item. See __Usage__ for instructions. Defaults to
  '`self-signed.example.com.crt`', and should be changed to something
  relevant for the local site before use, in a role or wrapper cookbook.

The following attributes are related to setting up a Splunk server with indexer
clustering in the `setup_clustering` recipe:

* `node['splunk']['clustering']`: A hash of indexer clustering configurations
  used in the `setup_clustering` recipe
* `node['splunk']['clustering']['enabled']`: Whether to enable indexer clustering,
  must be set to `true` to use the `setup_clustering` recipe. Defaults to `false`,
  must be a boolean literal `true` or `false`.
* `node['splunk']['clustering']['num_sites']`: The number of sites in the cluster.
  Multisite is enabled automatically if num_sites > 1. Defaults to 1, must be a positive integer.
* `node['splunk']['clustering']['mode']`: The clustering mode of the node within
  the indexer cluster. Must be set using string literal 'master',
  'slave', or 'searchhead'.
* `node['splunk']['clustering']['replication_port']`: The replication port
  of the cluster peer member. Only valid when `node['splunk']['clustering']['mode']='slave'`.
  Defaults to 9887.
* `node['splunk']['clustering']['mgmt_uri']` (Default: https://fqdn:8089)
  This attribute is for the indexer cluster members and cluster master. The cluster master
  will set this node attribute to itself, while all cluster members will perform a chef search
  to get the value from the cluster master's node data.

* For single-site clustering (`node['splunk']['clustering']['num_sites']` = 1):
  * `node['splunk']['clustering']['replication_factor']`: The replication factor
    of the indexer cluster. Defaults to 3, must be a positive integer. Only valid
    when `node['splunk']['clustering']['mode']='master'` and
    `node['splunk']['clustering']['num_sites']`=1 (single-site clustering).
  * `node['splunk']['clustering']['search_factor']`: The search factor
    of the indexer cluster. Only valid when `node['splunk']['clustering']['mode']='master'` and
    `node['splunk']['clustering']['num_sites']`=1 (single-site clustering). Defaults to 2, must be a positive integer.

* For multisite clustering (`node['splunk']['clustering']['num_sites']` > 1):
  * `node['splunk']['clustering']['site']`: The site the node belongs to. Valid values include site1 to site63
  * `node['splunk']['clustering']['site_replication_factor']`: The per-site replication policy
    of any given bucket. This is represented as a comma-separated list of per-site entries. Only valid
    when `node['splunk']['clustering']['mode']='master'` and multisite is true. Defaults to 'origin:2,total:3'.
    Refer to [Splunk Admin docs](http://docs.splunk.com/Documentation/Splunk/latest/Admin/serverconf) for exact syntax and more details.
  * `node['splunk']['clustering']['site_search_factor']`: The per-site search policy for searchable copies
    for any given bucket. This is represented as a comma-separated list of per-site entires. Only valid when
    `node['splunk']['clustering']['mode']='master'` and multisite is true. Defaults to 'origin:1,total:2'.
    Refer to [Splunk Admin docs](http://docs.splunk.com/Documentation/Splunk/latest/Admin/serverconf) for exact syntax and more details.

The following attributes are related to setting up a Splunk server with search head
clustering in the `setup_shclustering` recipe:

* `node['splunk']['shclustering']`: A hash of search head clustering configurations
  used in the `setup_shclustering` recipe
* `node['splunk']['shclustering']['app_dir']`: the path where search head clustering configuration will
  be installed (Default: /opt/splunk/etc/apps/0_autogen_shcluster_config)
* `node['splunk']['shclustering']['enabled']`: Whether to enable search head clustering,
  must be set to `true` to use the `setup_shclustering` recipe. Defaults to `false`,
  must be a boolean literal `true` or `false`.
* `node['splunk']['shclustering']['mode']`: The search head clustering mode of the node within
  the cluster. This is used to determine if the node needs to bootstrap the shcluster and initialize
  the node as the captain. Must be set using string literal 'member' or 'captain'.
* `node['splunk']['shclustering']['label']`: The label for the shcluster. Used to differentiate
  from other shclusters in the environment. Must be a string. Defaults to `shcluster1`.
  captain election. Must be set using string literal 'member' or 'captain'.
* `node['splunk']['shclustering']['replication_factor']`: The replication factor
  of the shcluster. Defaults to 3, must be a positive integer.
* `node['splunk']['shclustering']['replication_port']`: The replication port
  of the shcluster members. Defaults to 9900.
* `node['splunk']['shclustering']['deployer_url']`: The management url for the
  shcluster deployer server, must be set to a string such as: `https://deployer.domain.tld:8089`.
  This attribute is optional. Defaults to empty.
* `node['splunk']['shclustering']['mgmt_uri']`: The management url for the
  shcluster member node, must be set to a string such as: `https://shx.domain.tld:8089`. You can
  use the node's IP address instead of the FQDN if desired. Defaults to `https://#{node['fqdn']}:8089`.
* `node['splunk']['shclustering']['shcluster_members']`: An array of all search head
  cluster members referenced by their `mgmt_uri`. Currently this will do a Chef search for nodes that
  are in the same environment, with search head clustering enabled, and with the same
  cluster label. Alternatively, this can be hard-coded with a list of all shcluster
  members including the current node. Must be an array of strings. Defaults to an empty array.

The following attributes are related to setting up a splunk forwarder
with the `client` recipe

`node['splunk']['outputs_conf']` is a hash of configuration values that are used to dynamically populate the `outputs.conf` file's "`tcpout:splunk_indexers_PORT`" configuration section. Each key/value pair in the hash is used as configuration in the file. For example the `attributes/default.rb` has this:

```ruby
default['splunk']['outputs_conf'] = {
  'forwardedindex.0.whitelist' => '.*',
  'forwardedindex.1.blacklist' => '_.*',
  'forwardedindex.2.whitelist' => '_audit',
  'forwardedindex.filter.disable' => 'false'
}
```

This will result in the following being rendered in `outputs.conf`:

```
[tcpout:splunk_indexers_9997]
server=10.0.2.47:9997
forwardedindex.0.whitelist = .*
forwardedindex.1.blacklist = _.*
forwardedindex.2.whitelist = _audit
forwardedindex.filter.disable = false
```

As an example of `outputs_conf` attribute usage, to add an `sslCertPath` directive, define the attribute in your role or wrapper cookbook as such:

```
node.default['splunk']['outputs_conf']['sslCertPath'] = '$SPLUNK_HOME/etc/certs/cert.pem'
```
The `server` attribute in `tcpout:splunk_indexers_9997` stanza above is populated by default from Chef search results for Splunk servers, or, alternatively, is statically defined in node attribute `node['splunk']['server_list']`.

`node['splunk']['server_list']` is an optional comma-separated listed of server IPs and the ports. It's only applicable when there are no Splunk servers managed by Chef, e.g. sending data to Splunk Cloud which has managed indexers.

For example:
```
node.default['splunk']['server_list'] = '10.0.2.47:9997, 10.0.2.49:9997'
```


`node['splunk']['inputs_conf']` is a hash of configuration values that are used to populate the `inputs.conf` file.

* `node['splunk']['inputs_conf']['host']`: A string that specifies the
default host name used in the inputs.conf file. The inputs.conf file
is not overwritten if this is not set or is an empty string.
* `node['splunk']['inputs_conf']['ports']`: An array of hashes that contain
the input port configuration necessary to generate the inputs.conf
file.
* `node['splunk']['inputs_conf']['inputs']`: An array of hashes that contain
the input configuration necessary to generate the inputs.conf
file. This attribute supports all input types.

For example:
```
node.default['splunk']['inputs_conf']['ports'] = [
  {
    port_num => 123123,
    config => {
      'sourcetype' => 'syslog'
    }
  }
]

node.default['splunk']['inputs_conf']['inputs'] = [
  {
    input_path => 'monitor:///var/log/syslog',
    config => {
      'sourcetype' => 'syslog'
    }
  }
]

```

The following attributes are related to upgrades in the `upgrade`
recipe. **Note** The default upgrade version is set to 7.3.2 and should be modified to
suit in a role or wrapper, since we don't know what upgrade versions
may be relevant. Enabling the upgrade and blindly using the default
URLs may have undesirable consequences, hence this is not enabled, and
must be set explicitly elsewhere on the node(s).

* `node['splunk']['upgrade_enabled']`: Controls whether the upgrade is enabled and the `attributes/upgrade.rb` file should be loaded. Set this in a role or wrapper cookbook to perform an upgrade.

* `node['splunk']['server']['upgrade']['url']`: This is the URL to the desired server upgrade package only if `upgrade_enabled` is set.
* `node['splunk']['server']['upgrade']['version']`: specifies the target splunk server version for an upgrade. This is ignored if server upgrade URL is provided. (Default: 8.0.1)
* `node['splunk']['forwarder']['upgrade']['url']`: This is the URL to the desired forwarder upgrade package only if `upgrade_enabled` is set.
* `node['splunk']['forwarder']['upgrade']['version']`: specifies the target splunk universal forwarder version for an upgrade. This is ignored if forwarder upgrade URL is provided. (Default: 8.0.1)

* All URLs set in attributes must be direct download links and not redirects
* Set these attributes to `nil` or empty string `''` to force installing the packages from the
  OS package managers. In doing so, server owners are responsible for properly configuring their
  package manager so chef can install the package.

  For example, each line below will force the chef-client to install Splunk's Universal Forwarder and server
  from the local package manager:
  ```
  node.force_default['splunk']['forwarder']['upgrade']['url'] = ''
  node.force_default['splunk']['server']['upgrade']['url'] = ''
  node.force_default['splunk']['forwarder']['upgrade']['url'] = nil
  node.force_default['splunk']['server']['upgrade']['url'] = nil
  ```


## Custom Resources

### splunk_app

This resource will install a Splunk app or deployment app into the appropriate locations
on a Splunk Enterprise server. Some custom "apps" simply install with a few files to override
default Splunk settings. The latter is desirable for maintaining settings after an upgrade of the
Splunk Enterprise server software.

* Breaking Change *
As of v6.0.0, sub-resources of the `splunk_app` provider will no longer notify restarts to the `service[splunk]` resource. Restarts of the service must be handled explicitly by the `splunk_app` caller. This allows end-users of the resource more control of when splunkd gets restarted; especially in cases where an app does not require a restart when its files are updated.

#### Actions
* `:install`: Installs a Splunk app or deployment app. This action will also update existing app config files, as needed
* `:remove`: Completely removes a Splunk app or deployment app from the Splunk Enterprise server

#### Properties
### TODO: document the rest of the splunk_app properties

* `app_dir`: Specifies the application's installation path. Apps installed with this property will be done relative
  to the Splunk installation directory (Default: /opt/splunk).
* `local_file`: specifies a local path where an app will be sourced. This will not download an app from a remote
  source, as it assumes the file or bundle has been done so outside of this resource. With so many ways to "unpack" a compressed bundle file (e.g., tar.gz, zip, bz2), this feature will not attempt to support any/all of the possibilities. In contrast, this feature will support installing an app from any local source on the chef node and into the /opt/splunk/etc/apps directory, unless otherwise specified by the `app_dir` property.

* `templates`: This is either an array of template names or a Hash consisting of a target destination path and template names
  For example: `['server.conf.erb']` or `{ 'etc/deployment-apps' => 'server.conf.erb' }`.

* `template_variables`: This is a Hash with embedded Hash to specify variables that can be passed into the templates keyed by
  the name of the template, matching the template names in `templates` property above. The format of this Hash is such that
  a `default` Hash can specify variables/values passed to all templates or it can specify different variables/values for any and all
  templates.

  For example, this will pass the default Hash of variables/values into all of the templates, but the `foo.erb` template will
  be fed a unique Hash of variables/values.
  ```ruby
  splunk_app 'my app' do
    templates %w(foo.erb bar.erb server.conf.erb app.conf.erb outputs.conf.erb)
    template_variables {
      {
        'default' => { 'var1' => 'value1', 'var2' => 'value2' },
        'foo.erb' => { 'x' => 'snowflake template' }
      }
    }
  end
  ```


#### Examples

Install and enable a deployment client configuration that overrides default Splunk Enterprise configurations

- Given a wrapper cookbook called MyDeploymentClientBase with a folder structure as below:
```
MyDeploymentClientBase
    /templates
        /MyDeploymentClientBase
            deploymentclient.conf.erb
```

```ruby
splunk_auth_info = data_bag_item('vault', "splunk_#{node.chef_environment}")['auth']

splunk_app 'MyDeploymentClientBase' do
  splunk_auth splunk_auth_info
  templates ['deploymentclient.conf.erb']
  cookbook 'MyDeploymentClientBase'
  action %i(install enable)
end
```

The Splunk Enterprise server will have a filesystem created, as follows:
```
/opt/splunk/etc/apps/MyDeploymentClientBase/local/deploymentclient.conf
```



### splunk_installer

The Splunk Enterprise and Splunk Universal Forwarder package
installation is the same, save for the name of the package and the URL to
download. This custom resource abstracts the package installation to a
common baseline. Any new platform installation support should be added
by modifying the custom resource as appropriate. One goal of this
custom resource is to have a single occurrence of a `package` resource,
using the appropriate "local package file" provider per platform. For
example, on RHEL, we use `rpm` and on Debian we use `dpkg`.

Package files will be downloaded to Chef's file cache path (e.g.,
`file_cache_path` in `/etc/chef/client.rb`, `/var/chef/cache` by
default).

#### Actions
* `:run`: install the splunk server or splunk universal forwarder
* `:remove`: uninstall the splunk server or splunk universal forwarder
* `:upgrade`: upgrade an existing splunk or splunk universal forwarder package

The custom resource has two parameters.

* `name`: The name of the package (e.g., `splunk`, `splunkforwarder`).
* `url`: The URL to the package file.
* `package_name`: This is the name of the package to install, if it is different from
  the resource name.
* `version`: install/upgrade to this version, if `url` is not given

#### Examples

For example, if the nodes in the environment are all Debian-family,
and the desired splunkforwarder package is provided locally as
`splunkforwarder.deb` on an internal HTTP server:

```ruby
splunk_installer 'splunkforwarder' do
  url 'https://www-int.example.com/splunk/splunkforwarder.deb'
end
```

The `install_forwarder` and `install_server` recipes use the
custom resource with the appropriate `url` attribute.

## Recipes

This cookbook has several composable recipes that can be used in a
role, or a local "wrapper" cookbook. The `default`, `client`, and
`server` recipes are intended to be used wholesale with all the
assumptions they contain.

The general default assumption is that a node including the `default`
recipe will be a Splunk Universal Forwarder (client).

### client

This recipe encapsulates a completely configured "client" - a Splunk
Universal Forwarder configured to talk to a node that is the splunk
server (with node['splunk']['is_server'] true). The recipes can be
used on their own composed in a wrapper cookbook or role. This recipe
will include the `user`, `install_forwarder`, `service`, and
`setup_auth` recipes.

It will also search a Chef Server for a Splunk Enterprise (server)
node with `splunk_is_server:true` in the same `chef_environment` and
write out `etc/system/local/outputs.conf` with the server's IP and the
`receiver_port` attribute in the Splunk install directory
(`/opt/splunkforwarder`).

Setting node['splunk']['outputs_conf'] with key value pairs
updates the outputs.conf server configuration with those key value pairs.
These key value pairs can be used to setup SSL encryption on messages
forwarded through this client:

```
# Note that the ssl CA and certs must exist on the server.
node['splunk']['outputs_conf'] = {
  'sslCommonNameToCheck' => 'sslCommonName',
  'sslCertPath' => '$SPLUNK_HOME/etc/certs/cert.pem',
  'sslPassword' => 'password'
  'sslRootCAPath' => '$SPLUNK_HOME/etc/certs/cacert.pem'
  'sslVerifyServerCert' => false
}
```

The inputs.conf file can also be managed through this recipe if you want to
setup a splunk forwarder just set the  default host:

```
node['splunk']['inputs_conf']['host'] = 'myhost'
```
Then set up the port configuration for each input port:

```
node['splunk']['inputs_conf']['ports'] =
[
  {
    port_num => 123123,
    config => {
      'sourcetype' => 'syslog',
      ...
    }
  },
  ...
]
```


### default

The default recipe will include the `disabled` recipe if
`node['splunk']['disabled']` is true.

It will include the `client` or `server` recipe depending on whether
the `is_server` attribute is set.

The attribute use allows users to control the included recipes by
easily manipulating the attributes of a node, or a node's roles, or
through a wrapper cookbook.

### disabled

In some cases it may be required to disable Splunk on a particular
node. For example, it may be sending too much data to Splunk and
exceed the local license capacity. To use the `disabled` recipe, set
the `node['splunk']['disabled']` attribute to true, and include the
recipe on the required node, or just use the `default` recipe.

### install_forwarder

This recipe uses the `splunk_installer` custom resource to install the
splunkforwarder package from the specified URL (via the
`node['splunk']['forwarder']['url']` attribute).

### install_server

This recipe uses the `splunk_installer` custom resource to install the
splunk (Enterprise server) package from the specified URL (via the
`node['splunk']['server']['url']` attribute).

### server

This recipe encapsulates a completely configured "server" - Splunk
Enterprise configured to receive data from Splunk Universal Forwarder
clients. The recipe sets the attribute `node['splunk']['is_server']`
to true, and is included from the `default` recipe if the attribute is
true as well. The recipes can be used on their own composed in a
wrapper cookbook or role, too. This recipe will include the `user`,
`install_server`, `service`, and `setup_auth` recipes. It will also
conditionally include the `setup_ssl` and `setup_clustering` recipes
if enabled via the corresponding node attributes, as defined
in __Attributes__ above.

It will also enable Splunk Enterprise as an indexer, listening on the
`node['splunk']['receiver_port']`.

## service

This recipe sets up the `splunk` service, and applies to both client
and server use, since `splunk` is the same service for both
deployments of Splunk.

The attribute `node['splunk']['accept_license']` must be true in order
to set up the boot script. If it's true, then the boot script gets put
into place (`/etc/init.d/splunk` on Linux/Unix systems), with the
license accepted. The service is managed using the Chef `init` service
provider, which operates by using the `/etc/init.d/splunk` script for
start, stop, restart, etc commands.

## setup_auth

This recipe loads an encrypted data bag with the Splunk user
credentials as an `-auth` string, '`user:password`', using the
[chef-vault cookbook](https://supermarket.chef.io/cookbooks/chef-vault) helper method,
`chef_vault_item`. See __Usage__ for how to set this up. The recipe
will edit the specified user (assuming `admin`), and then write a
state file to `etc/.setup_admin_password` to indicate in future Chef
runs that it has set the password. If the password should be changed,
then that file should be removed.

## setup_clustering

This recipe sets up Splunk indexer clustering based on the node's
clustering mode or `node['splunk']['clustering']['mode']`. The attribute
`node['splunk']['clustering']['enabled']` must be set to true in order to
run this recipe. Similar to `setup_auth`, this recipes loads
the same encrypted data bag with the Splunk `secret` key (to be shared among
cluster members), using the [chef-vault cookbook](https://supermarket.chef.io/cookbooks/chef-vault)
helper method, `chef_vault_item`. See __Usage__ for how to set this up. The
recipe will edit the cluster configuration, and then write a state file to
`etc/.setup_cluster_{master|slave|searchhead}` to indicate in future Chef
runs that it has set the node's indexer clustering configuration. If cluster
configuration should be changed, then that file should be removed.

It will also search a Chef Server for a Splunk Enterprise (server)
node of type cluster master, that is with `splunk_clustering_enable:true` and
`splunk_clustering_mode:master` in the same `chef_environment` and
use that server's IP when configuring a cluster search head or a cluster
peer node to communicate with the cluster master (Refer to `master_uri` attribute
of clustering stanza in `etc/system/local/server.conf`).

Indexer clustering is used to achieve some data availability & recovery. To learn
more about Splunk indexer clustering, refer to [Splunk Docs](http://docs.splunk.com/Documentation/Splunk/latest/Indexer/Aboutclusters).

## setup_shclustering

This recipe sets up Splunk search head clustering. The attribute
`node['splunk']['shclustering']['enabled']` must be set to true in order to
run this recipe. Similar to `setup_auth`, this recipes loads
the same encrypted data bag with the Splunk `secret` key (to be shared among
cluster members), using the [chef-vault cookbook](https://supermarket.chef.io/cookbooks/chef-vault)
helper method, `chef_vault_item`. See __Usage__ for how to set this up. The
recipe will edit the cluster configuration, and then write a state file to
`etc/.setup_shcluster` to indicate in future Chef runs that it has set the node's
search head clustering configuration. If cluster configuration should be changed,
then that file should be removed.

It will also search a Chef Server for a Splunk Enterprise (server)
node of type cluster master, that is with `splunk_shclustering_enable:true` and
the same `splunk_shclustering_label` in the same `chef_environment` and
use that server's IP when building the list of `shcluster_members`.

The search head cluster configuration is deployed as a custom Splunk app that
is written to `etc/apps/0_autogen_shcluster_config` to take advantage of Splunk's
built in config layering. All nodes with `splunk_shclustering_enable:true` will
receive this app.

On the first Chef run on a node with `splunk_shclustering_mode:captain`, this recipe
will build and execute the Splunk command to bootstrap the search head cluster and
initiate the captain election process.

In addition to using this recipe for configuring the search head cluster members, you
will also have to manually configure a search head instance to serve as the
search head cluster's deployer. This is done by adding a `[shclustering]` stanza to
that instance's `etc/system/local/server.conf` with the same `pass4SymmKey = <secret>`
and the same `shcluster_label = <splunk_shclustering_label>`. This deployer is optional, but should be configured prior to
running the bootstrap on the captain and then the search head cluster member nodes
configured with this deployer node's mgmt_uri set in the member node's `splunk_shclustering_deployer_url`

Search head clustering is used to achieve high availability & scaling. To learn
more about Splunk search head clustering, refer to [Splunk Docs](http://docs.splunk.com/Documentation/Splunk/latest/DistSearch/AboutSHC).

## upgrade

**Important** Read the upgrade documentation and release notes for any
  particular Splunk version upgrades before performing an upgrade.
  Also back up the Splunk directory, configuration, etc.

This recipe can be used to upgrade a splunk installation, for example
from an existing 7.3.2 to 8.0.1. The default recipe can be used for
8.0.1 after upgrading earlier versions have been completed. Note that the
attributes file is only loaded w/ the URLs to the splunk packages to
upgrade if the `node['splunk']['upgrade_enabled']` attribute is set to
true. We recommend setting the actual URL attributes needed in a
wrapper cookbook or role.

## user

This recipe manages the `splunk` user and group. On Linux systems, the
user and group will be created with the `system` attribute; other
platforms may not be aware of `system` users/groups (e.g.,
illumos/solaris). Both resources will be created with the UID or GID
of the `node['splunk']['user']['uid']` attribute. The default value is
396, arbitrarily chosen to fall under the `system` UID/GID set by
`/etc/login.defs` on both RHEL and Debian family Linux systems. If
this is a conflicting UID/GID, then modify the attribute as required.

## Usage

### Data Bag Items

#### Splunk Secrets & Admin User Authentication

Splunk secret key and admin user authentication information should be stored in a
data bag item that is encrypted using Chef Vault. Create a data bag
named `vault`, with an item `splunk_CHEF-ENVIRONMENT`, where
`CHEF-ENVIRONMENT` is the `node.chef_environment` that the Splunk
Enterprise server will be assigned. If environments are not used, use
`_default`. For example in a Chef Repository (not in a cookbook):

    % cat data_bags/vault/splunk__default.json
    {
      "id": "splunk__default",
      "auth": "admin:notarealpassword",
      "secret": "notarealsecret"
    }

Or with an environment, '`production`':

    % cat data_bags/vault/splunk_production.json
    {
      "id": "splunk_production",
      "auth": "admin:notarealpassword",
      "secret": "notarealsecret"
    }

Then, upload the data bag item to the Chef Server using the
`chef-vault` `knife encrypt` plugin (first example, `_default`
environment):

    knife encrypt create vault splunk__default \
        --json data_bags/vault/splunk__default.json \
        --search 'splunk:*' --admins 'yourusername' \
        --mode client

More information about Chef Vault is available on the
[GitHub Project Page](https://github.com/Nordstrom/chef-vault).

#### Web UI SSL

A Splunk server should have the Web UI available via HTTPS. This can
be set up using self-signed SSL certificates, or "real" SSL
certificates. This loaded via a data bag item with chef-vault. Using
the defaults from the attributes:

    % cat data_bags/vault/splunk_certificates.json
    {
      "id": "splunk_certificates",
      "data": {
        "self-signed.example.com.crt": "-----BEGIN CERTIFICATE-----\n...SNIP",
        "self-signed.example.com.key": "-----BEGIN RSA PRIVATE KEY-----\n...SNIP"
      }
    }

Like the authentication credentials above, run the `knife encrypt`
command. Note the search here is for the splunk server only:

      knife encrypt create vault splunk_certificates \
          --json data_bags/vault/splunk_certificates.json \
          --search 'splunk_is_server:true' --admins 'yourusername' \
          --mode client


## License and Authors

- Author: Joshua Timberman <joshua@chef.io>
- Contributor: Dang H. Nguyen <dang.nguyen@disney.com>
- Copyright 2013-2019, Chef Software, Inc <legal@chef.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
