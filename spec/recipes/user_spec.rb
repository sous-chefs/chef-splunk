require_relative '../spec_helper.rb'

describe 'chef-splunk::user' do
  context 'os linux' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'ubuntu',
        version: '12.04'
      ).converge(described_recipe)
    end

    it 'creates a splunk group with the defaults from attributes' do
      expect(chef_run).to create_group('splunk').with('system' => true)
    end

    it 'creates a splunk user with the defaults from attributes' do
      expect(chef_run).to create_user('splunk').with('system' => true)
    end
  end

  context 'os non-linux' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(
        platform: 'omnios',
        version: '151018'
      ).converge(described_recipe)
    end

    # while `group` can have system set as a resource attribute, it
    # doesn't have a value set by default, so it will be nil. On the
    # other hand, `user` will have system false by default. Testing
    # that Chef works makes me a sad panda, but we're testing that the
    # OS specific handling does the right thing in the recipe.
    it 'creates a splunk group that does not have system true' do
      expect(chef_run).to create_group('splunk').with('system' => nil)
    end
    it 'creates a splunk user that does not have system true' do
      expect(chef_run).to create_user('splunk').with('system' => false)
    end
  end
end
