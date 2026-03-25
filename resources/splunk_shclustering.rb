# frozen_string_literal: true

provides :splunk_shclustering
unified_mode true

property :instance_name, String, name_property: true
property :install_dir, String, default: '/opt/splunk'
property :mode, String, required: true, equal_to: %w(deployer member captain)
property :label, String, required: true
property :replication_factor, Integer, default: 3
property :replication_port, Integer, default: 34567
property :mgmt_uri, String
property :deployer_url, String
property :secret, String, sensitive: true
property :splunk_auth, String, sensitive: true
property :runas_user, String, default: 'splunk'
property :app_dir, String, default: lazy { "#{install_dir}/etc/apps/0_PC_shcluster_config" }
property :shcluster_members, Array, default: []

action :create do
  case new_resource.mode
  when 'deployer'
    setup_deployer
  when 'member', 'captain'
    setup_member
  end
end

action_class do
  def setup_deployer
    directory new_resource.app_dir do
      owner new_resource.runas_user
      group new_resource.runas_user
      mode '755'
    end

    directory "#{new_resource.app_dir}/local" do
      owner new_resource.runas_user
      group new_resource.runas_user
      mode '755'
    end

    template "#{new_resource.app_dir}/local/server.conf" do
      source 'shclustering/deployer_server.conf.erb'
      cookbook 'chef-splunk'
      mode '600'
      owner new_resource.runas_user
      group new_resource.runas_user
      variables(
        label: new_resource.label,
        secret: new_resource.secret
      )
      sensitive true
    end
  end

  def setup_member
    execute 'initialize search head cluster member' do
      sensitive true
      command init_shcluster_command
      not_if { ::File.exist?("#{new_resource.install_dir}/etc/.setup_shclustering") }
    end

    file "#{new_resource.install_dir}/etc/.setup_shclustering" do
      action :nothing
      owner new_resource.runas_user
      group new_resource.runas_user
      mode '600'
      subscribes :touch, 'execute[initialize search head cluster member]'
    end
  end

  def init_shcluster_command
    cmd = "#{new_resource.install_dir}/bin/splunk init shcluster-config" \
          " -auth '#{new_resource.splunk_auth}'" \
          " -mgmt_uri #{new_resource.mgmt_uri}" \
          " -replication_port #{new_resource.replication_port}" \
          " -replication_factor #{new_resource.replication_factor}" \
          " -conf_deploy_fetch_url #{new_resource.deployer_url}" \
          " -secret #{new_resource.secret}" \
          " -shcluster_label #{new_resource.label}"
    return cmd if new_resource.runas_user == 'root'
    "su - #{new_resource.runas_user} -c '#{cmd}'"
  end
end
