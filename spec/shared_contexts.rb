shared_context 'command stubs' do
  before(:each) do
    allow_any_instance_of(Chef::Resource).to receive(:systemd?).and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:systemd?).and_return(true)

    stubs_for_resource('execute[initialize search head cluster member]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list shcluster-member-info -auth admin:notarealpassword')
    end
    stubs_for_resource('execute[add member to search head cluster]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list shcluster-member-info -auth admin:notarealpassword')
    end
    stubs_for_resource('execute[search head cluster integration with indexer cluster]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list search-server -auth admin:notarealpassword')
    end
    stubs_for_resource('service[splunk]') do |resource|
      allow(resource).to receive_shell_out("ps -ef|grep splunk|grep -v grep|awk '{print$1}'|uniq")
    end
    stubs_for_resource('execute[bootstrap-shcluster-captain]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk list shcluster-members -auth admin:notarealpassword | grep is_captain:1')
    end
    stubs_for_resource('execute[update-splunk-mgmt-port]') do |resource|
      allow(resource).to receive_shell_out("/opt/splunk/bin/splunk show splunkd-port -auth admin:notarealpassword | awk -F: '{print$NF}'")
    end
    stubs_for_resource('file[user-seed.conf]') do |resource|
      allow(resource).to receive_shell_out('/opt/splunk/bin/splunk login -auth admin:notarealpassword')
    end
  end
end
