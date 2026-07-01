# AGENTS.md

## Cookbook Purpose

Manage Splunk Enterprise or Splunk Universal Forwarder

## Agent Findings

* This cookbook is in an incremental modernization pass. Preserve existing public recipes and attributes unless a later full migration is explicitly selected.
* Dependency management should use `Policyfile.rb`; do not reintroduce Berkshelf.

## Known Limitations

This cookbook manages Splunk Enterprise and Splunk Universal Forwarder.

## Supported Platforms and Architectures

Based on Splunk 10.0 vendor documentation, the following platforms are supported:

### Linux x86_64 / ARM64 (AArch64)

- **Ubuntu**: 22.04, 24.04
- **Debian**: 12, 13
- **AlmaLinux**: 9, 10
- **Rocky Linux**: 9, 10
- **RHEL**: 9, 10
- **Amazon Linux**: 2023
- **openSUSE**: Leap 16

## Systemd Requirement

This cookbook exclusively supports `systemd` init systems. Legacy `sysvinit` and `upstart` support has been removed.

## Chef Version Requirement

- **Chef Infra Client**: 16.0 or newer (required for `unified_mode` and resource partials)
