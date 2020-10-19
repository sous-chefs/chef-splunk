# Disable file locking check by Splunk as it fails on unsupported file systems
# used in some Docker hosts (e.g. on Mac)
append_if_no_line 'Disable file locking check by Splunk startup' do
  action :nothing
  line 'OPTIMISTIC_ABOUT_FILE_LOCKING=1'
  path "#{splunk_dir}/etc/splunk-launch.conf"
  subscribes :edit, 'service[splunk]', :before
end
