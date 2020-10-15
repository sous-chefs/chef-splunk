if server?
  splunk_installer 'splunk 8.0.1' do
    url value_for_platform_family(
      %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
      'debian' => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
    )
  end
else
  splunk_installer 'splunk 8.0.1' do
    url value_for_platform_family(
      %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
      'debian' => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
    )
  end
end
