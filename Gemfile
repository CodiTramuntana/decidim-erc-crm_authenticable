# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gemspec

require_relative "lib/decidim/erc/crm_authenticable/version"

gem "decidim", ">=#{Decidim::Erc::CrmAuthenticable.decidim_version}"

group :development, :test do
  gem "bootsnap", require: true
  gem "byebug", platform: :mri
  gem "decidim-dev", ">=#{Decidim::Erc::CrmAuthenticable.decidim_version}"
  gem "faker"
  gem "listen"
end

group :development do
  gem "letter_opener_web", "~> 1.3.3"
  gem "web-console", "~> 3.5"
end
