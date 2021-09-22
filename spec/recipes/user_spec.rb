require 'spec_helper'

describe 'chef-splunk::user' do
  context 'os linux' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'ubuntu',
        version: '20.04'
      ).converge(described_recipe)
    end

    it 'creates a splunk group with the defaults from attributes' do
      expect(chef_run).to create_group('splunk').with('system' => true)
    end

    it 'creates a splunk user with the defaults from attributes' do
      expect(chef_run).to create_user('splunk').with('system' => true)
    end
  end
end
