# frozen_string_literal: true

provides :splunk_user
unified_mode true

property :username, String, name_property: true
property :uid, Integer, default: 396
property :gid, Integer, default: 396
property :comment, String, default: 'Splunk Server'
property :home, String, default: lazy { "/opt/#{username}" }
property :shell, String, default: '/bin/bash'

action :create do
  group new_resource.username do
    gid new_resource.gid
    system true
  end

  user new_resource.username do
    uid new_resource.uid
    gid new_resource.username
    comment new_resource.comment
    home new_resource.home
    shell new_resource.shell
    system true
    manage_home false
  end
end

action :remove do
  user new_resource.username do
    action :remove
  end

  group new_resource.username do
    action :remove
  end
end
