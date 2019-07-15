Decidim::Verifications.register_workflow(:crm_authenticable_authorization_handler) do |workflow|
  workflow.form = "Decidim::Erc::CrmAuthenticable::CrmAuthenticableAuthorizationHandler"
  workflow.engine = Decidim::Erc::CrmAuthenticable::Engine

  workflow.options do |options|
    options.attribute :membership_type_id, type: :string, required: false
    options.attribute :join_date, type: :string, required: false
  end

  workflow.action_authorizer = "Decidim::Erc::CrmAuthenticable::CrmAuthenticableActionAuthorizer"
end