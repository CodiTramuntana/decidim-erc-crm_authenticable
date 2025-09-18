# frozen_string_literal: true

# This decorator sets two additional attributes when creating users:
# extended_data: a Hash with data returned from CiviCRM.
# scope: a Decidim::Scope.
module Decidim::CreateRegistrationDecorator
  def self.decorate
    Decidim::CreateRegistration.class_eval do
      # Method overrided.
      # Log to crm_authenticable.log if Active Record Validations fail.
      def call
        return broadcast(:invalid) if form.invalid?

        create_user

        broadcast(:ok, @user)
      rescue ActiveRecord::RecordInvalid => e
        Decidim::Erc::CrmAuthenticable::Log.log.error("[#{self.class.name}] #{e.message}\n#{form.extended_data}")
        broadcast(:invalid)
      end

      private

      # Method overrided.
      # Add :extended_data and :scope to the attributes Hash.
      def create_user
        @user = Decidim::User.create!(
          email: form.email,
          name: form.name,
          nickname: form.nickname,
          password: form.password,
          password_updated_at: Time.current,
          organization: form.current_organization,
          tos_agreement: form.tos_agreement,
          newsletter_notifications_at: form.newsletter_at,
          accepted_tos_version: form.current_organization.tos_version,
          locale: form.current_locale,
          extended_data: form.extended_data,
          scope: find_scope_by_code
        )
      end

      # Method added.
      # Find a scope by a code stored in extended_data.
      def find_scope_by_code
        code = Decidim::Erc::CrmAuthenticable::SCOPE_CODES[form.extended_data[:member_of_code]]
        form.current_organization.scopes.find_by(code:)
      end
    end
  end
end

Decidim::CreateRegistrationDecorator.decorate
