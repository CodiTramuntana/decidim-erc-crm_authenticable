# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Devise
    describe SessionsController, type: :controller do
      routes { Decidim::Core::Engine.routes }

      let(:organization) { create(:organization) }
      let(:scope) { create(:scope, organization:) }
      let!(:user) do
        create(
          :user,
          :confirmed,
          email: "john.doe@example.org",
          password: "ppasswordd",
          organization:,
          scope:,
          extended_data: { document_number: Base64.strict_encode64("123456789A") }
        )
      end

      before do
        request.env["devise.mapping"] = ::Devise.mappings[:user]
        request.env["decidim.current_organization"] = user.organization
      end

      describe "POST create" do
        let(:params) do
          {
            user: { email: user.email, password: user.password }
          }
        end

        context "when the user is an admin" do
          before { user.update(admin: true) }

          it "does not try to authorize the user against CiviCRM" do
            expect(Decidim::Erc::CrmAuthenticable::UserAuthorizer).not_to receive(:new).with(user)
            post(:create, params:)
            expect(controller.flash.notice).to have_content("Signed in successfully.")
          end
        end

        context "when the user is an admin and mode is csv_mode" do
          before do
            user.update(admin: true)
            Rails.application.secrets.erc_crm_authenticable[:users_csv_path] = "users_csv_path"
          end

          after do
            Rails.application.secrets.erc_crm_authenticable[:users_csv_path] = nil
          end

          it "does not try to authorize the user against CSV" do
            expect(Decidim::Erc::CrmAuthenticable::UserAuthorizer).not_to receive(:new).with(user)
            post(:create, params:)
            expect(controller.flash.notice).to have_content("Signed in successfully.")
          end
        end

        context "when the params are invalid" do
          let(:params) { {} }

          it "does NOT log in the user" do
            post(:create, params:)
            expect(controller.flash.alert).to have_content("Invalid Email or password.")
          end
        end

        context "when the user is a militant of Esquerra Republicana" do
          before { stub_valid_request }

          it "logs in the user" do
            post(:create, params:)
            expect(controller.flash.notice).to have_content("Signed in successfully.")
          end
        end

        context "when the user is NO longer a militant of Esquerra Republicana" do
          before { stub_invalid_request_was_member }

          it "does NOT log in the user" do
            post(:create, params:)
            expect(controller.flash.alert).to have_content("Document number does not correspond to any dues-paying member of Esquerra Republicana.")
          end
        end

        context "when it fails to connect to CiviCRM" do
          before { stub_invalid_request_connection_error }

          it "does NOT log in the user" do
            post(:create, params:)
            expect(controller.flash.alert).to have_content("It was not possible to connect with CiviCRM. Please try again later.")
          end
        end
      end
    end
  end
end
