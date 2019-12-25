require 'spec_helper'

describe 'chef-splunk::setup_ssl' do
  let(:vault_item) do
    {
      'data' => {
        'self-signed.example.com.key' => '-----BEGIN RSA PRIVATE KEY-----',
        'self-signed.example.com.crt' => '-----BEGIN CERTIFICATE----',
      },
    }
  end

  context 'ssl enabled' do
    let(:runner) do
      ChefSpec::ServerRunner.new do |node|
        node.force_default['splunk']['ssl_options']['enable_ssl'] = true
        node.force_default['splunk']['is_server'] = true
        node.force_default['dev_mode'] = true
        node.force_default['splunk']['accept_license'] = true
      end
    end

    context 'default webui port' do
      let(:chef_run) do
        runner.converge(described_recipe)
      end

      before do
        allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return(vault_item)
      end

      it_behaves_like 'splunk daemon'

      it 'writes web.conf with http port 443' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('httpport = 443')
      end

      it 'enables SSL in the web.conf file' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('enableSplunkWebSSL = true')
      end

      it 'writes the SSL key from the data bag item' do
        keyfile = '/opt/splunk/etc/auth/splunkweb/self-signed.example.com.key'
        resrc = chef_run.file(keyfile)
        expect(chef_run).to create_file(keyfile).with(
          sensitive: true,
          mode: '600',
          owner: 'root',
          group: 'root'
        )
        expect(chef_run).to render_file(keyfile).with_content(/BEGIN RSA PRIVATE KEY/)
        expect(resrc).to notify('service[splunk]').to(:restart)
      end

      it 'writes the SSL certificate from the data bag item' do
        certfile = '/opt/splunk/etc/auth/splunkweb/self-signed.example.com.crt'
        resrc = chef_run.file(certfile)
        expect(chef_run).to create_file(certfile).with(
          sensitive: true,
          mode: '600',
          owner: 'root',
          group: 'root'
        )
        expect(chef_run).to render_file(certfile).with_content(/BEGIN CERTIFICATE/)
        expect(resrc).to notify('service[splunk]').to(:restart)
      end
    end

    context 'alternative webui port' do
      let(:chef_run) do
        runner.node.force_default['splunk']['web_port'] = '7777'
        runner.converge(described_recipe)
      end

      before do
        allow_any_instance_of(Chef::Recipe).to receive(:chef_vault_item).and_return(vault_item)
      end

      it_behaves_like 'splunk daemon'

      it 'writes web.conf with a non-default port for https' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('httpport = 7777')
      end
    end
  end
end
