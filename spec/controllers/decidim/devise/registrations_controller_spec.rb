# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Decidim::Devise::RegistrationsController, type: :controller do
    routes { Decidim::Core::Engine.routes }

    let(:organization) { create(:organization) }
    let!(:scope) { create(:scope, organization:, code: "custom_21") }

    before do
      request.env["devise.mapping"] = ::Devise.mappings[:user]
      request.env["decidim.current_organization"] = organization
    end

    describe "POST new_step_two" do
      let(:params) do
        {
          user: {
            sign_up_as: "user",
            document_number: "123456789A"
          }
        }
      end

      context "when the form is valid" do
        before { stub_valid_request }

        it "renders the new_step_2 template" do
          post(:new_step_2, params:)
          expect(controller).to render_template(:new_step_2)
        end
      end

      context "when the form is invalid" do
        before { stub_invalid_request_not_member }

        it "renders the new template" do
          post(:new_step_2, params:)
          expect(controller).to render_template(:new)
        end
      end
    end

    describe "POST create" do
      let(:params) do
        {
          user: {
            sign_up_as: "user",
            name: "User",
            nickname: "nickname",
            email:,
            password: "rPYWYKQJrXm97b4ytswc",
            tos_agreement: "1",
            newsletter: "0",
            phone_number: Base64.strict_encode64("666-666-666"),
            document_number: Base64.strict_encode64("123456789A"),
            member_of_code: "custom_21"
          }
        }
      end

      context "when the form is valid" do
        let(:email) { "test@example.org" }

        it "signs up the user" do
          post(:create, params:)
          expect(controller.flash.notice).to have_content("You have signed up successfully.")
        end
      end

      context "when the form is invalid" do
        let(:email) { nil }

        it "renders the new_step_two template" do
          post(:create, params:)
          expect(controller).to render_template(:new_step_2)
          expect(controller.flash.alert).to have_content("There was a problem creating your account.")
        end
      end
    end
  end
end
