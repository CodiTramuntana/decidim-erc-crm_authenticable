# frozen_string_literal: true

if Rails.env.test?
  Decidim::Erc::CrmAuthenticable::SCOPE_CODES = { "custom_21" => "custom_21" }.freeze
  Decidim::Erc::CrmAuthenticable::VALID_MBSP_STATUS_IDS = %(1).freeze
  Decidim::Erc::CrmAuthenticable::VALID_MBSP_JOIN_DATE = Date.yesterday.freeze
end