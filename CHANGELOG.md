# splunk CHANGELOG

This file is used to list changes made in each version of the splunk cookbook.

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
