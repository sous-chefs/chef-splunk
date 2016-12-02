apt_update 'update' if platform_family?('debian')

splunk_app 'bistro' do
  splunk_auth 'admin:notarealpassword'
  cookbook_file 'bistro-1.0.2.spl'
  checksum '862e2c4422eee93dd50bd93aa73a44045d02cb6232f971ba390a2f1c15bdb79f'
  action [:install, :enable]
end

splunk_app 'bistro-disable' do
  app_name 'bistro'
  splunk_auth 'admin:notarealpassword'
  action [:disable, :remove]
end

splunk_app 'sanitycheck' do
  remote_directory 'sanitycheck'
  splunk_auth 'admin:notarealpassword'
  action :install
end

splunk_app 'bistro-remote-file' do
  app_name 'bistro-1.0.2'
  remote_file 'https://github.com/ampledata/bistro/archive/1.0.2.tar.gz'
  splunk_auth 'admin:notarealpassword'
  templates ['inputs.conf']
  app_dependencies(
    if node['platform_family'] == 'omnios'
      ['ruby-19']
    else
      ['ruby']
    end
  )
  action :install
end
