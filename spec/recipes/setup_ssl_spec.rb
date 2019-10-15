require 'spec_helper'

describe 'chef-splunk::setup_ssl' do
  let(:certs) do
    {
      'splunk_certificates' => {
        'id' => 'splunk_certificates',
        'data' => {
          'self-signed.example.com.key' => '-----BEGIN RSA PRIVATE KEY-----',
          'self-signed.example.com.crt' => '-----BEGIN CERTIFICATE-----',
        },
      },
    }
  end

  context 'ssl enabled' do
    context 'default webui port' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new do |node, server|
          node.force_default['splunk']['ssl_options']['enable_ssl'] = true
          node.force_default['splunk']['is_server'] = true
          node.force_default['dev_mode'] = true
          node.force_default['splunk']['accept_license'] = true
          # Populate mock certs data into Chef server
          server.create_data_bag('vault', certs)
        end.converge(described_recipe)
      end

      it 'created the service[splunk] resource' do
        expect(chef_run.service('splunk')).to do_nothing
      end

      it 'includes chef-vault' do # ~FC005
        expect(chef_run).to include_recipe('chef-vault::default')
      end

      it 'writes web.conf with http port 443' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('httpport = 443')
      end

      it 'enables SSL in the web.conf file' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('enableSplunkWebSSL = true')
      end

      it 'writes the SSL key from the chef-vault data bag item' do
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

      it 'writes the SSL certificate from the chef-vault data bag item' do
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
        ChefSpec::ServerRunner.new do |node, server|
          node.force_default['splunk']['ssl_options']['enable_ssl'] = true
          node.force_default['splunk']['is_server'] = true
          node.force_default['splunk']['accept_license'] = true
          node.force_default['dev_mode'] = true
          node.force_default['splunk']['web_port'] = '7777'
          # Populate mock certs data into Chef server
          server.create_data_bag('vault', certs)
        end.converge(described_recipe)
      end

      it 'created the service[splunk] resource' do
        expect(chef_run.service('splunk')).to do_nothing
      end

      it 'writes web.conf with a non-default port for https' do
        expect(chef_run).to render_file('/opt/splunk/etc/system/local/web.conf').with_content('httpport = 7777')
      end
    end
  end
end
