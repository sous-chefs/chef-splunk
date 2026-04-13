# frozen_string_literal: true

arm64 = node['kernel']['machine'] == 'aarch64'
deb_arch = arm64 ? 'arm64' : 'amd64'
rpm_arch = arm64 ? 'aarch64' : 'x86_64'
tgz_arch = arm64 ? 'arm64' : 'amd64'

default['test']['forwarder_url'] = if arm64
                                     "https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-#{tgz_arch}.tgz"
                                   else
                                     value_for_platform_family(
                                       %w(rhel fedora suse amazon) => "https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6.#{rpm_arch}.rpm",
                                       'debian' => "https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-#{deb_arch}.deb"
                                     )
                                   end

default['test']['server_url'] = if arm64
                                  "https://download.splunk.com/products/splunk/releases/9.4.0/linux/splunk-9.4.0-6b4ebe426ca6-linux-#{tgz_arch}.tgz"
                                else
                                  value_for_platform_family(
                                    %w(rhel fedora suse amazon) => "https://download.splunk.com/products/splunk/releases/9.4.0/linux/splunk-9.4.0-6b4ebe426ca6.#{rpm_arch}.rpm",
                                    'debian' => "https://download.splunk.com/products/splunk/releases/9.4.0/linux/splunk-9.4.0-6b4ebe426ca6-linux-#{deb_arch}.deb"
                                  )
                                end

default['test']['upgrade_forwarder_url'] = if arm64
                                             "https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-#{tgz_arch}.tgz"
                                           else
                                             value_for_platform_family(
                                               %w(rhel fedora suse amazon) => "https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-#{rpm_arch}.rpm",
                                               'debian' => "https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-#{deb_arch}.deb"
                                             )
                                           end

default['test']['upgrade_server_url'] = if arm64
                                          "https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-#{tgz_arch}.tgz"
                                        else
                                          value_for_platform_family(
                                            %w(rhel fedora suse amazon) => "https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-#{rpm_arch}.rpm",
                                            'debian' => "https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-#{deb_arch}.deb"
                                          )
                                        end
