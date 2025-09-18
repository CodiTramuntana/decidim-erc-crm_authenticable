# frozen_string_literal: true

module Decidim
  module Erc
    module CrmAuthenticable
      # Custom Logger.
      class Log
        def self.log
          if @logger.nil?
            @logger = Logger.new(Rails.root.join("log/crm_authenticable.log"))
            @logger.level = Logger::DEBUG
            @logger.datetime_format = "%Y-%m-%d %H:%M:%S "
          end
          @logger
        end

        def self.log_error(error)
          log.error error.message
          log.error error.backtrace.join("\n")
        end
      end
    end
  end
end
