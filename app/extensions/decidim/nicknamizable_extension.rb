# frozen_string_literal: true

# Module to add a new method to override Nicknamizable::nicknamize
module Decidim::NicknamizableExtension
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Disambiguates nicknames, scoped to the organization.
    # The original method expects a name to convert to a nickname; but since
    # we already have a nickname, we only need the disambiguation logic.
    def nicknamize(nickname, scope = {})
      return unless nickname

      disambiguate(nickname, scope)
    end
  end
end
