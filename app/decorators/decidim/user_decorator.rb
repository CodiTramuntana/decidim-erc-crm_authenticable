# frozen_string_literal: true

# This decorator handles the easy acces of some pieces of information stored
# in the `extended_data` Hash, that are unique to the ERC app.
Decidim::User.class_eval do
  # Association added.
  belongs_to :scope, foreign_key: "decidim_scope_id", class_name: "Decidim::Scope", optional: true

  # Validation added.
  validates_presence_of :scope, unless: :admin?

  # Method added.
  #
  def crm_authorize!
    Decidim::Erc::CrmAuthenticable::UserAuthorizer.new(self).authorize!
  end

  # Method added.
  #
  def crm_authorized?
    Decidim::Authorization.exists?(user: self, name: "crm_authenticable_authorization_handler")
  end
end
