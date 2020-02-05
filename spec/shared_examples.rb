shared_examples 'a search head cluster member' do
  it 'executes initialize shcluster member command' do
    expect(chef_run).to_not run_execute('initialize search head cluster member')
  end

  it 'creates /opt/splunk/etc/.setup_shcluster' do
    expect(chef_run).to_not create_file('/opt/splunk/etc/.setup_shcluster')
  end
end

shared_examples 'splunk daemon' do
  it 'created the service[splunk] resource' do
    expect(chef_run).to start_service('splunk')
    expect(chef_run).to enable_service('splunk')
  end
end
