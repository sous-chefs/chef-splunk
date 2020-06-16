require 'spec_helper'

describe 'chef-splunk::service' do
  context 'splunkd as a server' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['splunk']['accept_license'] = true
        node.force_default['splunk']['is_server'] = true
      end.converge(described_recipe)
    end

    it 'creates directory /opt/splunk' do
      expect(chef_run).to create_directory('/opt/splunk').with(mode: '755')
    end

    %w(/opt/splunk/var /opt/splunk/var/log).each do |d|
      it "creates directory #{d}" do
        expect(chef_run).to create_directory(d).with(mode: '711')
      end
    end

    it 'creates directory /opt/splunk/var/log/splunk' do
      expect(chef_run).to create_directory('/opt/splunk/var/log/splunk').with(mode: '700')
    end

    it 'created /etc/systemd/system/splunk.service' do
      expect(chef_run).to create_template('/etc/systemd/system/splunk.service')
    end

    it 'deleted /etc/systemd/system/splunkd.service' do
      expect(chef_run).to delete_file('/etc/systemd/system/splunkd.service')
    end

    it 'creates resource execute[systemctl daemon-reload] to do_nothing' do
      expect(chef_run.execute('systemctl daemon-reload')).to do_nothing
    end

    it 'does not delete /etc/systemd/system/splunk.service' do
      expect(chef_run).to_not delete_file('/etc/systemd/system/splunk.service')
    end

    it 'does not create /etc/init.d/splunk' do
      expect(chef_run).to_not create_template('/etc/init.d/splunk')
    end

    it 'starts the splunk service' do
      expect(chef_run).to start_service('splunk')
    end

    it 'enables the splunk service' do
      expect(chef_run).to enable_service('splunk')
    end
  end
end
