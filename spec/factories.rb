# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/surveys/test/factories"

FactoryBot.modify do
  factory :user, class: "Decidim::User" do
    scope { create(:scope, organization:) } # Adding this.
    nickname { "Nickname" }
  end
end
