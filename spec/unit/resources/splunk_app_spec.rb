# frozen_string_literal: true

require 'spec_helper'

describe 'splunk_app' do
  step_into :splunk_app
  platform 'ubuntu', '24.04'

  context 'action :install with cookbook_file' do
    recipe do
      splunk_app 'myapp' do
        cookbook_file 'myapp.tgz'
      end
    end

    it { is_expected.to install_splunk_app('myapp') }
  end

  context 'action :install with remote_file' do
    recipe do
      splunk_app 'myapp' do
        remote_file 'https://example.com/myapp.tgz'
      end
    end

    it { is_expected.to install_splunk_app('myapp') }
  end

  context 'action :install with remote_directory' do
    recipe do
      splunk_app 'myapp' do
        remote_directory 'myapp'
      end
    end

    it { is_expected.to install_splunk_app('myapp') }
  end

  context 'action :install with templates as array' do
    recipe do
      splunk_app 'myapp' do
        templates %w(inputs.conf.erb outputs.conf.erb)
      end
    end

    it { is_expected.to install_splunk_app('myapp') }
  end

  context 'action :install with templates as hash' do
    recipe do
      splunk_app 'myapp' do
        templates('local/inputs.conf' => 'inputs.conf.erb')
      end
    end

    it { is_expected.to install_splunk_app('myapp') }
  end

  context 'action :remove' do
    recipe do
      splunk_app 'myapp' do
        action :remove
      end
    end

    it { is_expected.to remove_splunk_app('myapp') }
  end
end
