# frozen_string_literal: true

module Splunk
  module Resources
    module AuthHelpers
      def auth_user
        new_resource.splunk_auth&.split(':')&.first
      end

      def auth_password
        new_resource.splunk_auth&.split(':')&.last
      end
    end
  end
end
