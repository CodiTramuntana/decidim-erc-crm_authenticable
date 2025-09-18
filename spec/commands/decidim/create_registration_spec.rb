# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Comments
    describe CreateRegistration do
      describe "call" do
        let(:organization) { create(:organization) }
        let!(:scope) { create(:scope, organization:, code: "custom_21") }

        let(:form) do
          RegistrationForm.from_params(params).with_context(current_organization: organization)
        end
        let(:params) do
          {
            user: {
              name: "Username",
              nickname: "nickname",
              email: "user@example.org",
              password: "Y1fERVzL2F",
              tos_agreement: "1",
              current_locale: "ca",
              newsletter: "1"
            }.merge(extended_data)
          }
        end
        let(:extended_data) do
          {
            phone_number:,
            document_number: Base64.strict_encode64("123456789A"),
            member_of_code: scope.code
          }
        end
        let(:phone_number) { "666-666-666" }
        let(:command) { described_class.new(form) }

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new user" do
            expect(User).to receive(:create!).with(
              name: form.name,
              nickname: form.nickname,
              email: form.email,
              password: form.password,
              tos_agreement: form.tos_agreement,
              newsletter_notifications_at: form.newsletter_at,
              email_on_notification: true,
              organization:,
              accepted_tos_version: organization.tos_version,
              extended_data: extended_data.merge(phone_number: Base64.strict_encode64(phone_number)),
              scope:
            ).and_call_original

            expect { command.call }.to change(User, :count).by(1)
          end
        end

        describe "when the command fails to find the scope by code" do
          before { extended_data[:member_of_code] = "different_code" }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end
      end
    end
  end
end
