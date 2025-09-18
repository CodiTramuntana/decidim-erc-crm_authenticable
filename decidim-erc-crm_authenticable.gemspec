# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/erc/crm_authenticable/version"

DECIDIM_VERSION = ">= 0#{Decidim::Erc::CrmAuthenticable.decidim_version}".freeze

Gem::Specification.new do |s|
  s.version = Decidim::Erc::CrmAuthenticable.version
  s.authors = ["Isaac Massot"]
  s.email = ["isaac.mg@coditramuntana.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/CodiTramuntana/decidim-erc-crm_authenticable/"
  s.required_ruby_version = ">= 3.2.2"

  s.name = "decidim-erc-crm_authenticable"
  s.summary = "A decidim Erc::CrmAuthenticable module"
  s.description = "Integration with CiviCrm for ERC."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", DECIDIM_VERSION
  s.add_dependency "decidim-verifications", DECIDIM_VERSION
  s.add_dependency "rest-client"

  # concurrent-ruby v1.3.5 has removed the dependency on logger
  s.add_dependency "concurrent-ruby", "1.3.4"

  s.metadata["rubygems_mfa_required"] = "true"
end
