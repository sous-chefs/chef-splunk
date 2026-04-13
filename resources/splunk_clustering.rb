# frozen_string_literal: true

provides :splunk_clustering
unified_mode true

property :instance_name, String, name_property: true
property :install_dir, String, default: '/opt/splunk'
property :mode, String, required: true, equal_to: %w(master slave searchhead)
property :replication_factor, Integer, default: 3
property :search_factor, Integer, default: 2
property :replication_port, Integer, default: 9887
property :master_uri, String
property :num_sites, Integer, default: 1
property :site, String
property :site_replication_factor, String
property :site_search_factor, String
property :splunk_auth, String, sensitive: true, required: true
property :secret, String, sensitive: true
property :runas_user, String, default: 'splunk'

action :create do
  cmd_params = build_cluster_params

  file "#{new_resource.install_dir}/etc/.setup_clustering" do
    action :nothing
    owner new_resource.runas_user
    group new_resource.runas_user
    mode '600'
    subscribes :touch, 'execute[setup-indexer-cluster]'
  end

  execute 'setup-indexer-cluster' do
    command cluster_command(cmd_params)
    sensitive true
    environment(
      'SPLUNK_USER' => auth_user,
      'SPLUNK_PASSWORD' => auth_password
    )
    retries 5
    retry_delay 60
    not_if { ::File.exist?("#{new_resource.install_dir}/etc/.setup_clustering") }
  end
end

action_class do
  def auth_user
    new_resource.splunk_auth.split(':').first
  end

  def auth_password
    new_resource.splunk_auth.split(':')[1]
  end

  def multisite?
    new_resource.num_sites > 1
  end

  def build_cluster_params
    case new_resource.mode
    when 'master'
      build_master_params
    when 'slave', 'searchhead'
      build_member_params
    end
  end

  def build_master_params
    params = +'-mode master'
    if multisite?
      available_sites = (1..new_resource.num_sites).to_a.map { |i| "site#{i}" }.join(',')
      params << " -multisite true -available_sites #{available_sites} -site #{new_resource.site}" \
                " -site_replication_factor #{new_resource.site_replication_factor}" \
                " -site_search_factor #{new_resource.site_search_factor}"
    else
      params << " -replication_factor #{new_resource.replication_factor}" \
                " -search_factor #{new_resource.search_factor}"
    end
    append_secret(params)
  end

  def build_member_params
    params = +"-mode #{new_resource.mode}"
    params << " -site #{new_resource.site}" if multisite?
    params << " -master_uri #{new_resource.master_uri}" \
              " -replication_port #{new_resource.replication_port}"
    append_secret(params)
  end

  def append_secret(params)
    params << " -secret #{new_resource.secret}" if new_resource.secret
    params
  end

  def cluster_command(params)
    cmd = "#{new_resource.install_dir}/bin/splunk edit cluster-config #{params} -auth '#{new_resource.splunk_auth}'"
    return cmd if new_resource.runas_user == 'root'
    "su - #{new_resource.runas_user} -c '#{cmd}'"
  end
end
