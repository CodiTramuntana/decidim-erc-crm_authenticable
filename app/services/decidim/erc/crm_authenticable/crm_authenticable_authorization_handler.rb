# frozen_string_literal: true

require "digest"
require "csv"

module Decidim
  module Erc
    module CrmAuthenticable
      # A form object used to handle ID number validations against CiviCRM.
      class CrmAuthenticableAuthorizationHandler < Decidim::AuthorizationHandler
        attribute :document_number, String

        validates :document_number,
                  format: { with: /\A[A-Z0-9]*\z/, message: I18n.t("errors.messages.uppercase_only_letters_numbers") },
                  presence: true

        validate :ws_request_must_succeed, :ws_response_must_return_valid_membership, if: -> { ::Decidim::Erc::CrmAuthenticable.crm_mode? }

        def unique_id
          Digest::SHA512.hexdigest(
            "#{document_number}-#{Rails.application.secrets.erc_crm_authenticable[:secret_key]}"
          )
        end

        # Injects the valid membership into the `metadata` field of the authorization.
        # This information will be used by CrmAuthenticableActionAuthorizer.
        def metadata
          super.merge(@membership || {})
        end

        # Allows to validate the document_number against the CiviCRM WS without a User.
        # See Decidim::Erc::CrmAuthenticable::IdentityDocumentForm#document_number_must_be_valid
        def document_valid?
          if ::Decidim::Erc::CrmAuthenticable.csv_mode?
            authentication_against_csv_must_succeed
          else
            ws_request_must_succeed
            ws_response_must_return_valid_membership
          end
          errors.empty?
        end

        attr_reader :response

        private

        # Validates the request succeeded. Does not proceed if document_number format is invalid.
        def ws_request_must_succeed
          return if errors.any?

          @response = CiviCrmClient.new.find_militant(document_number)

          errors.add(:base, I18n.t("connection_failed", scope: "crm_authenticable.errors")) if response[:error]
        end

        def authentication_against_csv_must_succeed
          return if errors.any?

          @response = nil

          csv = CSV.read(Rails.application.secrets.erc_crm_authenticable[:users_csv_path])

          user = csv.find { |row| row.first == document_number }

          if user.present?
            @response = {
              body:
              [
                {
                  display_name: user[1],
                  email: user[2],
                  phone: user[3],
                  custom_21: user[4]
                }.transform_keys(&:to_s)
              ]
            }
          else
            errors.add(:base, I18n.t("user_not_found", scope: "census"))
          end
        end

        # Validates the document_number against CiviCRM. Does not proceed if the WS request fails.
        def ws_response_must_return_valid_membership
          return if errors.any?

          errors.add(:document_number, I18n.t("document_invalid", scope: "crm_authenticable.errors")) unless valid_membership?
        end

        # Searches the body of the WS response for a valid CiviCRM Contact and Memberbership.
        def valid_membership?
          @membership = begin
            contact = response.dig(:body, 0)
            return false if contact.blank?

            memberships = contact.dig("api.Membership.get", "values")
            memberships.find do |mbsp|
              mbsp["membership_name"].in?(VALID_MBSP_NAMES) &&
                mbsp["status_id"].in?(VALID_MBSP_STATUS_IDS) &&
                Date.parse(mbsp["join_date"]) <= VALID_MBSP_JOIN_DATE
            end
          end
        end
      end
    end
  end
end
