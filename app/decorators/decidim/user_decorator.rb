# frozen_string_literal: true

require "decidim/nicknamizable_extension"

# This decorator associates the model with a Decidim::Scope (optional for admins).
# and adds public methods related to crm_authenticable_authorization_handler.
module Decidim::UserDecorator
  def self.decorate
    Decidim::User.class_eval do
      # Mixin added.
      include Decidim::NicknamizableExtension

      # Association added.
      belongs_to :scope, foreign_key: "decidim_scope_id", class_name: "Decidim::Scope", optional: true

      # Validation added.
      validates_presence_of :scope, unless: :admin?

      # Method added.
      # Authorizes the user after validating the extended_data with CrmAuthenticableAuthorizationHandler.
      # Returns a Hash with the response.
      def crm_authorize!
        ::Decidim::Erc::CrmAuthenticable::UserAuthorizer.new(self).authorize!
      end

      # Method added.
      # Checks if the user is authorized against CiviCRM.
      # Returns a boolean.
      def crm_authorized?
        Decidim::Authorization.exists?(user: self, name: "crm_authenticable_authorization_handler")
      end
    end
  end
end

Decidim::UserDecorator.decorate
