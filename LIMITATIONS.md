# Splunk Cookbook Limitations

This cookbook manages Splunk Enterprise and Splunk Universal Forwarder.

## Supported Platforms and Architectures

Based on Splunk 9.4.0 vendor documentation, the following platforms are supported:

### Linux x86_64 / ARM64 (AArch64)

- **Ubuntu**: 22.04, 24.04
- **Debian**: 12
- **RHEL / Rocky Linux / AlmaLinux**: 9
- **Amazon Linux**: 2023
- **SUSE**: Leap 15

## Systemd Requirement

This cookbook exclusively supports `systemd` init systems. Legacy `sysvinit` and `upstart` support has been removed.

## Chef Version Requirement

- **Chef Infra Client**: 16.0 or newer (required for `unified_mode` and resource partials)
