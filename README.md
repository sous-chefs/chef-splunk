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

Chef 11.10.0+ for `declare_resource`.

### Platforms

This cookbook uses Test Kitchen to do cross-platform convergence and
post-convergence tests. The tested platforms are considered supported.
This cookbook may work on other platforms or platform versions with or
without modification.

* Debian 7
* Ubuntu 12.04, 14.04
* CentOS 6
* OmniOS r151008

### Cookbooks

Used for managing secrets, see __Usage__:

* chef-vault

## Attributes

Attributes have default values set in `attributes/default.rb`. Where
possible or appropriate, the default values from Splunk Enterprise are
used.

General attributes:

* `node['splunk']['accept_license']`: Whether to accept the Splunk
  EULA. Default is false. This *must* be set to true for Splunk to be
  functional with this cookbook, which means end users must read the
  EULA and agree to the terms.
* `node['splunk']['is_server']`: Set this to true if the node is a
  splunk server, for example in a role. Default is false.
* `node['splunk']['disabled']`: Disable the splunk agent by setting
  this to true. Default is false.
* `node['splunk']['receiver_port']`: The port that the receiver
  (server) listens to. This is set to the Splunk Enterprise default,
  9997.
* `node['splunk']['web_port']`: The port that the splunkweb service
  listens to. This is set to the default for HTTPS, 443, as it is
  configured by the `setup_ssl` recipe.
* `node['splunk']['ratelimit_kilobytessec']`: The default splunk rate limiting rate can now easily be changed with an attribute.  Default is 2048KBytes/sec.

The two URL attributes below are selected by platform and architecture
by default.

* `node['splunk']['forwarder']['url']`: The URL to the Splunk
  Universal Forwarder package file.
* `node['splunk']['server']['url']`: The URL to the Splunk Enterprise
  package file.

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
  `splunk_ceritficates`.
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
* `node['splunk']['clustering']['enable']`: Whether to enable indexer clustering,
  must be set to `true` to use the `setup_clustering` recipe. Defaults to `false`,
  must be a boolean literal `true` or `false`.
* `node['splunk']['clustering']['mode']`: The clustering mode of the node within
  the indexer cluster. Must be set using string literal 'master',
  'slave', or 'searchhead'.
* `node['splunk']['clustering']['replication_factor']`: The replication factor
  of the indexer cluster. Defaults to 3, must be a positive integer. Only valid
  when `node['splunk']['clustering']['mode']='master'`.
* `node['splunk']['clustering']['search_factor']`: The search factor
  of the indexer cluster. Only valid when `node['splunk']['clustering']['mode']='master'`.
  Defaults to 2, must be a positive integer.
* `node['splunk']['clustering']['replication_port']`: The replication port
  of the cluster peer member. Only valid when `node['splunk']['clustering']['mode']='slave'`.
  Defaults to 9887.

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

The `tcpout:splunk_indexers_9997` section is defined by the search results for Splunk Servers, and the `server` directive is a comma-separated listed of server IPs and the ports. For example, to add an `sslCertPath` directive, define the attribute in your role, wrapper cookbook, etc:

```
node.default['splunk']['outputs_conf']['sslCertPath'] = '$SPLUNK_HOME/etc/certs/cert.pem'
```

`node['splunk']['inputs_conf']` is a hash of configuration values that are used to populate the `inputs.conf` file.

* `node['splunk']['inputs_conf']['host']`: A string that specifies the
default host name used in the inputs.conf file. The inputs.conf file
is not overwritten if this is not set or is an empty string.
* `node['splunk']['inputs_conf']['ports']`: An array of hashes that contain
the input port configuration necessary to generate the inputs.conf
file.

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
```

The following attributes are related to upgrades in the `upgrade`
recipe. **Note** The version is set to 4.3.7 and should be modified to
suit in a role or wrapper, since we don't know what upgrade versions
may be relevant. Enabling the upgrade and blindly using the default
URLs may have undesirable consequences, hence this is not enabled, and
must be set explicitly elsewhere on the node(s).

* `node['splunk']['upgrade_enabled']`: Controls whether the upgrade is
  enabled and the `attributes/upgrade.rb` file should be loaded. Set
  this in a role or wrapper cookbook to perform an upgrade.
* `node['splunk']['upgrade']`: Sets `server_url` and `forwarder_url`
  attributes based on platform and architecture. These are only loaded
  if `upgrade_enabled` is set.

## Definitions

### splunk_installer

The Splunk Enterprise and Splunk Universal Forwarder package
installation is the same save the name of the package and the URL to
download. This definition abstracts the package installation to a
common baseline. Any new platform installation support should be added
by modifying the definition as appropriate. One goal of this
definition is to have a single occurance of a `package` resource,
using the appropriate "local package file" provider per platform. For
example, on RHEL, we use `rpm` and on Debian we use `dpkg`.

Package files will be downloaded to Chef's file cache path (e.g.,
`file_cache_path` in `/etc/chef/client.rb`, `/var/chef/cache` by
default).

The definition has two parameters.

* `name`: The name of the package (e.g., `splunk`).
* `url`: The URL to the package file.

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
definition with the appropriate `url` attribute.

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

Setting node['splunk']['tcpout_server_config_map'] with key value pairs
updates the outputs.conf server configuration with those key value pairs.
These key value pairs can be used to setup SSL encryption on messages
forwarded through this client:

```
# Note that the ssl CA and certs must exist on the server.
node['splunk']['tcpout_server_config_map'] = {
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

This recipe uses the `splunk_installer` definition to install the
splunkforwarder package from the specified URL (via the
`node['splunk']['forwarder']['url']` attribute).

### install_server

This recipe uses the `splunk_installer` definition to install the
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
[chef-vault cookbook](http://ckbk.it/chef-vault) helper method,
`chef_vault_item`. See __Usage__ for how to set this up. The recipe
will edit the specified user (assuming `admin`), and then write a
state file to `etc/.setup_admin_password` to indicate in future Chef
runs that it has set the password. If the password should be changed,
then that file should be removed.

## setup_clustering

This recipe sets up Splunk indexer clustering based on the node's
clustering mode or `node['splunk']['clustering']['mode']`. The attribute
`node['splunk']['clustering']['enable']` must be set to true in order to
run this recipe. Similar to `setup_auth`, this recipes loads
the same encrypted data bag with the Splunk `secret` key (to be shared among
cluster members), using the [chef-vault cookbook](http://ckbk.it/chef-vault)
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

## upgrade

**Important** Read the upgrade documentation and release notes for any
  particular Splunk version upgrades before performing an upgrade.
  Also back up the Splunk directory, configuration, etc.

This recipe can be used to upgrade a splunk installation, for example
from an existing 4.2.1 to 4.3.7. The default recipe can be used for
6.0.1 after upgrading earlier versions is completed. Note that the
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
- Copyright 2013, Chef Software, Inc <legal@chef.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
