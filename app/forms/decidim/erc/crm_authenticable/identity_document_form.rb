# frozen_string_literal: true

module Decidim
  module Erc
    module CrmAuthenticable
      # A form object used to validate ID numbers with CrmAuthenticableAuthorizationHandler.
      class IdentityDocumentForm < Form
        mimic :user

        attribute :document_number, String

        validates :document_number,
                  format: { with: /\A[A-Z0-9]*\z/, message: I18n.t("errors.messages.uppercase_only_letters_numbers") },
                  presence: true

        validate :document_number_must_be_valid, :document_number_must_be_unique

        # Returns a Hash to be used as params to build a RegistrationForm.
        # Returns an empty hash if document_number is invalid or it hasn't been validated yet.
        def registration_form_params
          return {} if errors.any? || authorization_handler.response.nil?

          {
            name: user_data["display_name"],
            email: user_data["email"],
            phone_number: user_data["phone"],
            document_number: encoded_document_number,
            member_of_code: user_data["custom_21"]
          }
        end

        private

        # Validates the document_number against CiviCRM.
        # Does not proceed if document_number format is invalid or
        # the CrmAuthenticableAuthorizationHandler validation fails.
        def document_number_must_be_valid
          return if errors.any? || authorization_handler.document_valid?

          if authorization_handler.errors.attribute_names.include?(:document_number)
            errors.add(:document_number, I18n.t("document_invalid", scope: "crm_authenticable.errors"))
          elsif Decidim::Erc::CrmAuthenticable.csv_mode? && authorization_handler.errors.attribute_names.include?(:base)
            errors.add(:base, I18n.t("user_not_found", scope: "census"))
          else
            errors.add(:base, I18n.t("connection_failed", scope: "crm_authenticable.errors"))
          end
        end

        # Validates the document_number against CiviCRM.
        # Does not proceed if document_number is invalid.
        def document_number_must_be_unique
          return if errors.any?

          errors.add(:document_number, I18n.t("duplicate_user", scope: "crm_authenticable.errors")) if duplicates.any?
        end

        # Caches a CrmAuthenticableAuthorizationHandler instance.
        def authorization_handler
          @authorization_handler ||= CrmAuthenticableAuthorizationHandler.from_params(document_number:)
        end

        # Searches User's with the same document_number (encoded) in the metadata attribute.
        def duplicates
          Decidim::User
            .where(organization: current_organization)
            .where("extended_data @> ?", { document_number: encoded_document_number }.to_json)
        end

        # Returns a Hash with specific user data from CiviCRM.
        def user_data
          @user_data ||= authorization_handler.response[:body][0].slice(*CiviCrmClient::USER_DATA)
        end

        def encoded_document_number
          Base64.strict_encode64(document_number)
        end
      end
    end
  end
end
