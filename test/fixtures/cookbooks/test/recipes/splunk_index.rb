# this recipe tests the `splunk_index` resource in Test Kitchen
indexes_dir = "#{splunk_dir}/etc/apps/chef_splunk_indexes"

remote_directory indexes_dir do
  source 'chef_splunk_indexes'
  action :create_if_missing
  recursive true
end

splunk_index 'linux_messages_syslog' do
  indexes_conf_path "#{indexes_dir}/local/indexes.conf"
  options(
    'homePath' => '$SPLUNK_DB/syslog/db',
    'coldPath' => '$SPLUNK_DB/syslog/colddb',
    'thawedPath' => '$SPLUNK_DB/splunk/indexer_thaweddata/syslog/thaweddb',
    'frozenTimePeriodInSecs' => 31536000,
    'repFactor' => 'auto'
  )
  only_if { ::File.exist?("#{indexes_dir}/local/indexes.conf") }
end
