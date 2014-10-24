splunk CHANGELOG
================

v1.3.0 (2014-10-24)
-------------------

- Implement dynamic inputs.conf and outputs.conf configuration based on attributes in client recipe.

v1.2.2 (2014-08-25)
-------------------

- Implement capability to run Splunk as a non-root user
- Allow web port to be specified

v1.2.0 (2014-05-06)
-------------------
- [COOK-4621] - upgrade to Splunk 6.0.3 (for heartbleed)
- add ubuntu 14.04 to test-kitchen

v1.1.0 (2014-03-19)
-------------------
- [COOK-4450] - upgrade to Splunk 6.0.2
- [COOK-4451] - unbreak test harness

v1.0.4
------
- template sources should have .erb explicitly
- don't show the password in the execute resource name

v1.0.2
------
- Splunk init script supports status, use it in `stop` action for upgrade.

v1.0.0
-----
- Initial release

