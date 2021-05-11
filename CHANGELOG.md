# splunk CHANGELOG

This file is used to list changes made in each version of the splunk cookbook.

## Unreleased

- resolved cookstyle error: resources/splunk_app.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/splunk_index.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/splunk_installer.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/splunk_monitor.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
## 7.2.0 - *2021-03-12*

- Sous Chefs Adoption
- Re-vamp inspec tests for test-kitchen
- Various cookstyle & spec fixes

## 7.1.0 (2020-11-30)

- Adds cookbook dependency on [ec2-tags-ohai-plugin](https://supermarket.chef.io/cookbooks/ec2-tags-ohai-plugin) to read EC2 tags as a secondary detection method for rotating Splunk secrets

## 7.0.3 (2020-11-02)

- Fixes Issue #128 logic in `#shcluster_members?` helper method with a better match

## 7.0.2 (2020-10-30)

- Fix centos-6 and Amazon linux convergence by adding an only_if to only create systemd symlinks on systemd systems.
- Adds clarification text to README.md regarding chef-vault fallback to encrypted data bags
- Changes the build status badge to track Actions status

## 7.0.1 (2020-10-30)

- Moves most tests back to dokken and only run suites that change splunk user from root in vagrant.

## 7.0.0 (2020-10-22)

### BREAKING CHANGE

- sets umask when executing the `execute[splunk enable boot-start]` resource
- adds new attribute, `default['splunk']['enable_boot_start_umask']` for umask setting applied to `execute[splunk enable boot-start]` (Default: '18')
- `#splunk_cmd` now requires a dynamic array of arguments that will be appended to the splunk command
- `splunk.service` is symlinked to the systemd unit
- adds a kitchen-vagrant config to run inside Github Actions
- enhancements to the `:remove` action for `splunk_installer` resource to ensure a complete uninstall for both Splunk Enterprise Server and Universal Forwarder

## 6.4.1 (2020-10-20)

- Fixes an issue running Splunk and the Splunk Universal Forwarder as a non-root user
- Fixes Test Kitchen configuration to test running Splunk as non-root user
- Helper methods in `libraries/helper.rb` are moved to their own module space: `ChefSplunk::Helpers`
- Disables Splunk management port (8089) when installing the Universal Forwarder

## 6.4.0 (2020-10-19)

- Fixes Issue [#185](https://github.com/chef-cookbooks/chef-splunk/issues/185)
  - a startup issue was resolved for SplunkForwarder installations with an improved systemd unit file (fix below)
  - Adds Inspec tests to verify from SplunkForwarder starts (thanks, [@jjm](https://github.com/jjm))
- Fixes Issue [#187](https://github.com/chef-cookbooks/chef-splunk/issues/187)
  - the systemd unit file is now relegated to the `splunk enable boot-start` command to manage
- Adds Inspec tests and sets the verifier in Test Kitchen for some test suites; some are still in serverspec
- Render the user-seed.conf with a file resource rather than a template
- The default recipe no longer includes the disable recipe; to disable splunk, add `recipe[chef-splunk::disabled]` to a run list explicitly
- Disabling splunk will no longer uninstall Splunk Enterprise nor the Splunk Universal Forwarder
- Adds `#SecretsHelper` to aid with secrets rotation and maintaining idempotency for handling Splunk's hashed secret values
- Improved guards to prevent `service[splunk]` restart/start when it should be disabled.

## 6.3.0 (2020-10-14)

- Fixes Issue [#183](https://github.com/chef-cookbooks/chef-splunk/issues/183): make upgrades idempotent
- it is no longer necessary to include `chef-splunk::upgrade` to a run list; Instead, set the following:
  - set `node['splunk']['server']['upgrade']['version']` or `node['splunk']['forwarder']['upgrade']['version']` for the appropriate server type
  - set `node['splunk']['server']['upgrade']['url']` or `node['splunk']['forwarder']['upgrade']['url']` for the appropriate server type
  - set `node['splunk']['upgrade_enabled'] = true`

## 6.2.11 (2020-10-14)

- Sets the Splunk Enterprise Server and Forwarder upgrade versions to 8.0.6
- Sets the upgrade attributes to pull v8.0.6 of Splunk Enterprise and Universal Forwarder

## 6.2.10 (2020-07-15)

- Fixes Issue [#178](https://github.com/chef-cookbooks/chef-splunk/issues/178)
- `#shcluster_member?` passes `node['ipaddress']` to `#include?`

## 6.2.9 (2020-07-01)

- Drops travis-ci and onboards testing with Github Actions
- removes dependency on the splunk command when running the `disable` recipe

## 6.2.8 (2020-07-01)

- Thank you, [@doublethink](https://github.com/doublethink), for this submission
- Resolves issues installing server and client as non-root users:
  - `chef-splunk::user` recipe will not run if splunkd should be run as a non-root user
  - systemd and SysV templates correctly run as the specified non-root user
- Adds a new helper method: `#run_as_root?`

## 6.2.7 (2020-06-29)

- Fixes Issue [#168](https://github.com/chef-cookbooks/chef-splunk/issues/168)
  - uses `node.normal` when `ruby_block[captain elected]` executes to persist that value between chef runs
  - requires manually updating node data to set `node.normal['splunk']['shclustering']['captain_elected'] = true` if you've already deployed v6.2.6 of this cookbook previously otherwise, skip v6.2.6 and run v6.2.7 directly.

## 6.2.6 (2020-06-16)

- changes `#shcaptain_elected?` to rely on the splunk CLI output from `show shcluster-status` to determine if a captain has been elected
- adds new helper method: `#shcluster_captain` that returns `nil` or the name of the captain
- handles the case where `node['splunk']['shclustering']['mode'] == 'captain'` and the node is replacing one that was part of an existing cluster in a dynamic captain situation; whereby captaincy has migrated to a different node and the incoming "captain" should in fact add itself as a regular member of the search head cluster.

## 6.2.5 (2020-06-16)

- Fixes splunkd restart issue

## 6.2.4 (2020-06-15)

- Multiple bugfixes to resolve build issues
- Better chefspec coverage
- Installs a limits.conf as a custom Splunk app, called `chef_splunk_universal_forwarder`

## 6.2.3 (2020-06-15)

- Fixes overzealous splunkd restarts due to SysV template being deployed where Systemd exists after the rendered template is deleted by a `file` resource

## 6.2.2 (2020-06-14)

- Fixes systemd error: `Failed to enable unit: File /etc/systemd/system/splunk.service already exists.` This changes the systemd alias to `splunkd.service`

## 6.2.1 (2020-06-14)

- Removes `execute['enable boot-start']` resource that was conflicting with this cookbook's own templates for system start scripts

## 6.2.0 (2020-06-09)

- [PR#170](https://github.com/chef-cookbooks/chef-splunk/pull/170) - Support systemd natively (@mfortin)

## 6.1.9 (2020-06-02)

- Standardise files with files in chef-cookbooks/repo-management - [@xorimabot](https://github.com/xorimabot)
- Chef Infra Client 16 compatibility fixes - [@xorimabot](https://github.com/xorimabot)
  - resolved cookstyle error: resources/splunk_app.rb:19:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: resources/splunk_index.rb:17:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: resources/splunk_installer.rb:17:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: resources/splunk_monitor.rb:17:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`

## 6.1.8 (2020-05-13)

- gracefully handles return value when splunk hasn't been installed for these helper methods:
  - `#shcaptain_elected?`
  - `#ok_to_bootstrap_captain?`
  - `#ok_to_add_member?`
  - `#search_heads_peered?`

## 6.1.7 (2020-05-13)

- Fixes `#init_shcluster_member?` exception when splunk is not installed; will return false when splunk hasn't been installed

## 6.1.6 (2020-04-28)

- Rescues `Errno::ENOENT` in `ruby_block['splunk_fix_file_ownership']`

## 6.1.5 (2020-03-30)

- Fixes issues [#158](https://github.com/chef-cookbooks/chef-splunk/issues/158)
  - Removes default_description as a property field

## 6.1.4 (2020-03-26)

- Implements a `cookbook` property for the `splunk_app` custom resource

## 6.1.3 (2020-03-16)

- applies `files_mode` property to `remote_directory` resource used by the `splunk_app` resource

## 6.1.2 (2020-03-16)

- adds property `files_mode` to the `splunk_app` resource that allows downstream recipes to set the mode for a template being managed by the resource.

## 6.1.1 (2020-03-12)

- Removes iniparse gem install from metadata; this was superfluous

## 6.1.0 (2020-03-11)

- Fixes Issue [#64](https://github.com/chef-cookbooks/chef-splunk/issues/64)
  - Adds custom resource, `splunk_monitor`
  - Adds custom resource, `splunk_index`
- Disables STDOUT/STDERR suppression for execute resources when Chef Infra Client is run in `:debug` mode

## 6.0.0 (2020-03-07)

- Changes the restart behavior of `splunk_app` to eliminate sub-resources of the resource from
  initiating restarts of service[splunk]
- Fixes Issue [#59](https://github.com/chef-cookbooks/chef-splunk/issues/59)
  - converts `splunk_app` resource to modern style

## 5.0.4 (2020-03-07)

- Fixes Issue [#152](https://github.com/chef-cookbooks/chef-splunk/issues/152)
  - Removes `splunk_auth` property from the `splunk_app` resources (no longer required)

## 5.0.3 (2020-03-06)

- fixes minimum number of search head cluster members required to bootstrap the captain
- fixes search head cluster captain discovery
- fixes the logic that determines when a search head cluster captain can be bootstrapped
- fixes the logic that determines when a search head cluster member can be added to its cluster
- adds helper methods:
  - `#shcluster_member?`
  - `#shcaptain_elected?`
  - `#ok_to_bootstrap_captain?`
  - `#ok_to_add_member?`
  - `#shcluster_servers_list`
  - `#hash_password`
- To prevent overzealous restarts of splunkd, detects when the pass4symmkey has already been encrypted by splunkd

## 5.0.2 (2020-02-20)

- removes unnecessary `#run_command` calls when `shell_out` is used

## 5.0.1 (2020-02-10)

- Fixes Issue [#146](https://github.com/chef-cookbooks/chef-splunk/issues/146)

## 5.0.0 (2020-02-10)

- `splunk_app` no longer uses the `splunk install app` and `splunk disable app` commands; preference to managing the files in `<splunk_dir>/etc/apps`, or the alternative directories, directly, and restarting/reloading Splunk, as needed.
- Removes these actions from `splunk_app`: `:disable`, `:enable`, and `:update`
- `splunk_app` now has two actions only: `:install` (default) and `:remove`
  - `:install` action will also update app config files, as needed
- Fixes Issue [#111](https://github.com/chef-cookbooks/chef-splunk/issues/111)
  - with so many ways to "unpack" a compressed bundle file (e.g., tar.gz, zip, bz2), this feature will not attempt to support any/all of the possibilities. In contrast, this feature will support installing an app from any local source on the chef node and into the /opt/splunk/etc/apps directory, unless otherwise specified by the `app_dir` property.
- The `sensitive` property is honored by the `splunk_app` resource.

## 4.1.0 (2020-02-06)

- Adds attribute `node['splunk']['shclustering']['app_dir']` to take the place of local ruby variable to set the search head clustering application directory.
- Uses the splunk CLI to add search head cluster members instead of the app server.conf file to ensure members are properly added. SH cluster members wait for the captain to converge.
- Search Head Captains will initialize as a search head cluster member and then bootstrap themselves
- Improves idempotent addition of search head cluster members
- Fixes issue [#137](https://github.com/chef-cookbooks/chef-splunk/issues/137)
  - Adds logic to skip any initialization or bootstrapping of search head cluster resources.
- Fixes issue [#138](https://github.com/chef-cookbooks/chef-splunk/issues/138)
  - Adds a new property to the `splunk_app` resource, called `template_variables`
- Fixes issue [#139](https://github.com/chef-cookbooks/chef-splunk/issues/139)
  - Adds `cookbook` property to the template declared in the `splunk_app` provider
- Fixes issue [#140](https://github.com/chef-cookbooks/chef-splunk/issues/140)
  - Adds back resource actions: :enable, :disable, :install, :remove
- Fixes issue [#141](https://github.com/chef-cookbooks/chef-splunk/issues/141)
  - `app_dir` property was added to the `splunk_app` resource
- Integrates a search head cluster to a single or multisite indexer cluster
- Adds helper method `#add_shcluster_member?` to indicate whether a search head cluster member needs to be added to the search head cluster
- Adds support for Hash when providing the `templates` property to the `splunk_app` resource
- Adds `:update` action to `splunk_app` resource

## 4.0.5 (2020-01-15)

- Adds a state file and a guard that ensures the `template[user-seed.conf]` resource is idempotent
- Fixes the shcluster-captain bootstrap command where `--servers_list` was provided a semi-colon separated list instead of a comma-separated list

## 4.0.4 (2020-01-14)

- Fixes [#134](https://github.com/chef-cookbooks/chef-splunk/issues/134)

## 4.0.3 (2020-01-02)

- Changes the chef-vault cookbook dependency to `~> 4.0`. This version of chef-vault skips the gem installation via the cookbook, because the gem is included out of the box in Chef Infra Client 13.4+.

## 4.0.2 (2020-01-02)

- Modifies the `chef-splunk::shclustering` to deploy a Splunk Search Head deployer
- Fixes a regression made by commit 26fa04d9: when `node['splunk']['runasroot']` is false, splunk isn't started with a non-root user or the startup scripts are not modified to allow for non-root splunk commands
- Properly stops and restarts the splunk daemon when the daemon needs to switch from running as root to a non-root user
- Sets the splunk user home directory to the appropriate path when `node['splunk']['is_server']` is true
- Stops the splunk service, if installed, before modifying the splunk user account settings
- ensures the splunk service resources are always starting the daemon
- Ensures the splunk daemon is always running as the correct user

## 4.0.1 (2019-12-19)

- Fixes [#130](https://github.com/chef-cookbooks/chef-splunk/issues/130) the `execute[update-splunk-mgmt-port]` resource passes splunk auth info to the `#current_mgmt_port` helper method
- cookstyle auto-correct
- deletes .foodcritic and .rubocop.yml files from the repo

## 4.0.0 (2019-12-16)

- Installs Enterprise Splunk 8.0.1
- Installs Splunk Universal Forwarder 8.0.1
- Removes unnecessary calls to `include_recipe 'chef-vault'`
- in `chef-splunk::client`, do not install the forwarder if the server config is being installed on a splunkd server
- adds helper method: `#server?` that will return true if the chef node is a splunkd server
- adds helper method: `#port_open?` that will return true if the local node has a specified port open
- logs a warning message if `node['splunk']['upgrade']['server_url']` or `node['splunk']['upgrade']['forwarder_url']` exist
- Splunk now generates its own scripts for boot starts; therefore this cookbook executes Splunk's `boot-start` command

## 3.1.1 (2019-12-05)

- Fixes [#125](https://github.com/chef-cookbooks/chef-splunk/issues/125) adds conditional expressions when `node['splunk']['setup_auth']` is `false` to bypass the `chef-splunk::setup_auth` recipe.
- Fixes [#126](https://github.com/chef-cookbooks/chef-splunk/issues/126) creates `$SPLUNK_HOME/etc/system/local/user-seed.conf`

## 3.1.0 (2019-10-16)

- Fixes [#50](https://github.com/chef-cookbooks/chef-splunk/issues/50) `splunk_installer` now allows for installing the package bundle from OS package managers by specifying `package_name` and `version`

## 3.0.0 (2019-10-15)

- This release is brought to you by @haidangwa. Thanks!
- Added `upgrade` action to `splunk_installer` resource
- Fixed `chef-splunk::upgrade` recipe to actually upgrade splunk
- Fixed issue [#122](https://github.com/chef-cookbooks/chef-splunk/issues/122) removed `initial_captain` reference from comment
- `node['splunk']['accept_license']` is strictly enforced and documented that the value must be set to boolean `true`. Anything else will be considered not acceptig the license agreement.
- Ensures that the splunk directory has proper permissions and ownership set when splunk is run as a non-root user
- DRY chefspec examples
- cookstyle auto-corrects
- added Test Kitchen suites: `upgrade_server` and `uninstall_forwarder`
- Updated travis-ci config to include more test cases
- Fixed default upgrade URLs so they are not HTTP Redirect targets for debian platform family
- Accepted the license in startup scripts if accepted in attributes
- removed from Test Kitchen under dokken: debian 8
- added to Test Kitchen under dokken: debian 10 and ubuntu 18.04
- ensured that all recipes declare the service[splunk] resource consistently
- added helper methods: `#svc_command` and `#license_accepted?`
- Configure amazonlinux and fedora instances in kitchen-dokken and chefspec to run correctly.

## 2.0.0 (2019-10-01)

- Fixed issue [#58](https://github.com/chef-cookbooks/chef-splunk/issues/58) Converted the `splunk_installer` definition into a custom resource
- Fixed issue [#101](https://github.com/chef-cookbooks/chef-splunk/issues/101) Added sensitive true to the execute resources with commands containing splunk auth
- Fixed issue [#106](https://github.com/chef-cookbooks/chef-splunk/issues/106) splunk service runs as splunk user now
- Fixed issue [#118](https://github.com/chef-cookbooks/chef-splunk/issues/118) removed omnios platform tests
- bumped chef-vault dependency to `>= 3.1.1`
- moved content from files/default and templates/default in accordance with modern file specificity rules
  - Require Chef 13.11 or newer
- Removed (undocumented) support for Solaris (OmniOS) platform; omnios is not a platform
  that can currently be tested under ChefSpec and Test Kitchen.
- fixes to ensure splunk run as a non-root user
- added helper methods: `#splunk_runas_user` and `#splunk_service_provider`
- Fixed logic in setup_shcluster recipe and fixed the corresponding chefspec
- added `sensitive true` for SSL certificate private key and certificate resources
- ensured yum-centos repository is enabled in Test Kitchen for tests requiring centos or redhat

## 1.7.3 (2018-04-27)

- Set ownership of web.conf file using the splunk owner/group attributes

## 1.7.2 (2017-11-06)

- set the systemd unit file to 644

## 1.7.1 (2017-09-25)

- Enable amazon platform support for splunk forwarder
- Resolve deprecation warning in Chefspec and use the latest platforms in the specs

## v1.7.0 (2017-06-25)

- Fix CI and Kitchen Dokken
- Fix upgrade recipe
- Fix install on SUSE platform
- Add Splunk 6.6 URLs as default
- Add static list of indexers for client recipe
- Add multisite indexer clustering
- Add search head clustering
- Add ['splunk']['splunk_servers'] attribute as an alternative to using chef search functionality to discover splunk servers.

## v1.6.0 (2016-07-19)

- Updated the default version of the Splunk forwarder to 6.4
- Removed the scope section of the readme as this is no longer a Chef Ops maintained cookbook

## v1.5.0 (2016-03-14)

- Set the default version to 6.3.3 with working URLs
- Added integration testing in Travis CI with Kitchen Docker
- Added a scope to the readme to properly set expectations
- Added travis and cookbook version badges to the readme
- Removed Ubuntu 10.04 as a supported version and add 14.04
- Resolved all Rubocop warnings
- Pinned Gemfile to specific supported versions
- Added the Apache 2.0 license file
- Added maintainers.toml and maintainers.md files
- Replaced the testing.md file with a link to the docs repo
- Added long_description to the metadata
- Added source_url and issues_url for Supermarket to the metadata

## v1.4.0 (2015-09-13)

Also known as the "it's about time!" release

- support for splunk universal client running as a server
- update splunk install version to 6.2.1
- added attribute for rate limiting maxKBps throughput
- Add recipe to setup indexer cluster
- use `declare_resource` method to setup the right local-file package resource for `splunk_installer` definition
- lots of fixes for specs and tests

## v1.3.0 (2014-10-24)

- Implement dynamic inputs.conf and outputs.conf configuration based on attributes in client recipe.

## v1.2.2 (2014-08-25)

- Implement capability to run Splunk as a non-root user
- Allow web port to be specified

## v1.2.0 (2014-05-06)

- [COOK-4621] - upgrade to Splunk 6.0.3 (for heartbleed)
- add ubuntu 14.04 to test-kitchen

## v1.1.0 (2014-03-19)

- [COOK-4450] - upgrade to Splunk 6.0.2
- [COOK-4451] - unbreak test harness

## v1.0.4

- template sources should have .erb explicitly
- don't show the password in the execute resource name

## v1.0.2

- Splunk init script supports status, use it in `stop` action for upgrade.

## v1.0.0

- Initial release
