# frozen_string_literal: true

def auth_user
  new_resource.splunk_auth&.split(':')&.first
end

def auth_password
  new_resource.splunk_auth&.split(':')&.last
end
