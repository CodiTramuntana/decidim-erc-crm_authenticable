# frozen_string_literal: true

module Decidim
  module Erc
    module CrmAuthenticable
      # This class holds the logic to authorize users using CrmAuthenticableAuthorizationHandler.
      class UserAuthorizer
        def initialize(user)
          @user = user
          @document_number = user.extended_data["document_number"] || ""
        end

        def authorize!
          if authorization_handler.valid?
            create_or_update_crm_authorization!
            { authorized: true }
          else
            revoke_crm_authorization!
            { authorized: false, error: authorization_handler.errors.full_messages.first }
          end
        end

        private

        attr_reader :user, :document_number

        def authorization_handler
          @authorization_handler ||= CrmAuthenticableAuthorizationHandler.from_params(
            user:,
            document_number: Base64.strict_decode64(document_number)
          )
        end

        def create_or_update_crm_authorization!
          Authorization.create_or_update_from(authorization_handler)
        end

        def revoke_crm_authorization!
          Authorization.find_by(user:, name: authorization_handler.handler_name)&.destroy!
        end
      end
    end
  end
end
