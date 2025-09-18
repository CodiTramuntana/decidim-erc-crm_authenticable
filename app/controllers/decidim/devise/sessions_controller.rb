# frozen_string_literal: true

module Decidim
  module Devise
    # Custom Devise SessionsController to avoid namespace problems.
    class SessionsController < ::Devise::SessionsController
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods

      before_action :check_sign_in_enabled, only: :create

      # Method overrided.
      # Authorize the user against CiviCRM (not admins).
      # Sign in the user only if authorized or is an admin.
      # Otherwise, sign out the user and show error.
      def create
        result = current_user&.crm_authorize! unless current_user&.admin? || ::Decidim::Erc::CrmAuthenticable.csv_mode?

        if result.nil? || result[:authorized]
          super
        else
          sign_out
          flash[:alert] = result[:error]
          redirect_to new_user_session_path
        end
      end

      def pending_redirect?(user)
        store_location_for(user, stored_location_for(user))
      end

      def after_sign_out_path_for(user)
        request.referer || super
      end

      private

      def check_sign_in_enabled
        redirect_to new_user_session_path unless current_organization.sign_in_enabled?
      end
    end
  end
end
