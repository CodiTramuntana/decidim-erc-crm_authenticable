# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Erc
    module CrmAuthenticable
      describe UserAuthorizer do
        let!(:organization) { create(:organization) }
        let!(:scope) { create(:scope, code: "custom_21", organization:) }
        let(:user) { create(:user, scope:, organization:, extended_data:) }
        let(:extended_data) { { "document_number" => Base64.strict_encode64("123456789A") } }
        let(:handler_name) { Decidim::Erc::CrmAuthenticable::CrmAuthenticableAuthorizationHandler.handler_name }

        shared_examples_for "deleting an authorization" do
          it "deletes an existing `CrmAuthenticable` authorization for the user" do
            authorization = create(:authorization, name: handler_name, user:)

            expect { subject }.to change {
              Decidim::Authorization.exists?(authorization.id)
            }.from(true).to(false)
          end
        end

        describe "authorize!" do
          subject { described_class.new(user).authorize! }

          context "when document_number is valid against CiviCRM" do
            before { stub_valid_request }

            it { is_expected.to include(authorized: true) }

            it "creates a `CrmAuthenticable` authorization for the user" do
              expect { subject }.to change(Decidim::Authorization, :count)
            end

            it "updates an existing `CrmAuthenticable` authorization for the user" do
              authorization = create(:authorization, name: handler_name, user:, granted_at: 1.day.ago)

              expect { subject }.to(change { authorization.reload.granted_at })
            end
          end

          context "when document_number NOT is valid against CiviCRM" do
            let(:error) { "Document number does not correspond to any dues-paying member of Esquerra Republicana." }

            before { stub_invalid_request_not_member }

            it { is_expected.to include(authorized: false, error:) }

            it_behaves_like "deleting an authorization"
          end

          context "when it fails to connect to CiviCRM" do
            let(:error) { "It was not possible to connect with CiviCRM. Please try again later." }

            before { stub_invalid_request_connection_error }

            it { is_expected.to include(authorized: false, error:) }

            it_behaves_like "deleting an authorization"
          end

          context "when user's extended_data does not contain a document_number" do
            let(:extended_data) { {} }
            let(:error) { "Document number can't be blank" }

            before { stub_invalid_request_not_member }

            it { is_expected.to include(authorized: false, error:) }

            it_behaves_like "deleting an authorization"
          end
        end
      end
    end
  end
end
