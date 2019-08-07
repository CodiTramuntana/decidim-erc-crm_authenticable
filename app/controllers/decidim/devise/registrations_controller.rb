# frozen_string_literal: true

module Decidim
  module Devise
    # This controller customizes the behaviour of Devise's
    # RegistrationsController so we can specify a custom layout.
    class RegistrationsController < ::Devise::RegistrationsController
      include FormFactory
      include Decidim::DeviseControllers
      include NeedsTosAccepted

      before_action :check_sign_up_enabled
      before_action :configure_permitted_parameters

      invisible_captcha

      def new
        @form = form(Decidim::Erc::CrmAuthenticable::IdentityDocumentForm).from_params(
          user: {
            sign_up_as: "user"
          }
        )
      end

      def new_step_2
        @form = form(Decidim::Erc::CrmAuthenticable::IdentityDocumentForm).from_params(params[:user])
        return render :new unless @form.valid?

        @form = form(Decidim::RegistrationForm).from_params(
          user: {
            sign_up_as: "user"
          }.merge(@form.registration_form_params)
        )
      end

      def create
        @form = form(Decidim::RegistrationForm).from_params(params[:user])

        CreateRegistration.call(@form) do
          on(:ok) do |user|
            set_flash_message! :notice, :signed_up
            respond_with user, location: after_sign_up_path_for(user)
          end

          on(:invalid) do
            set_flash_message! :alert, :error
            render :new_step_2
          end
        end
      end

      protected

      def check_sign_up_enabled
        redirect_to new_user_session_path unless current_organization.sign_up_enabled?
      end

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :tos_agreement])
      end

      # Called before resource.save
      def build_resource(hash = nil)
        super(hash)
        resource.organization = current_organization
      end
    end
  end
end
