# frozen_string_literal: true

require "spec_helper"
require "decidim/dev/test/authorization_shared_examples"

module Decidim
  module Erc
    module CrmAuthenticable
      describe CrmAuthenticableAuthorizationHandler do
        let(:handler) { described_class.new(params) }
        let(:params) { { user:, document_number: } }
        let(:scope) { create(:scope) }
        let(:user) { create(:user, scope:, organization: scope.organization) }
        let(:document_number) { "123456789A" }

        it_behaves_like "an authorization handler"

        describe "metadata" do
          subject { handler.metadata }

          context "when document_number is valid against CiviCRM" do
            let(:membership_data) do
              {
                "membership_type_id" => a_kind_of(String),
                "join_date" => a_kind_of(String)
              }
            end

            before do
              stub_valid_request
              handler.validate
            end

            it { is_expected.to include(membership_data) }
          end

          context "when document_number NOT is valid against CiviCRM" do
            before do
              stub_invalid_request_not_member
              handler.validate
            end

            it { is_expected.to be_empty }
          end

          context "when it fails to connect to CiviCRM" do
            before do
              stub_invalid_request_connection_error
              handler.validate
            end

            it { is_expected.to be_empty }
          end

          context "when handler has not been validated yet" do
            it { is_expected.to be_empty }
          end
        end

        describe "metadata on CSV mode" do
          subject { handler.document_valid? }

          before do
            allow(::Decidim::Erc::CrmAuthenticable).to receive(:csv_mode?).and_return(true)
            Rails.application.secrets.erc_crm_authenticable[:users_csv_path] = "spec/fixtures/files/csv_users.csv"
          end

          after do
            Rails.application.secrets.erc_crm_authenticable[:users_csv_path] = nil
          end

          context "when document_number is valid against CSV" do
            it { is_expected.to be(true) }
          end

          context "when document_number NOT is valid against CSV" do
            let(:document_number) { "444444444M" }

            it { is_expected.to be(false) }
          end
        end

        shared_examples "validate document_number against CiviCRM" do
          context "when document_number format is not valid" do
            let(:document_number) { "(╯°□°）╯︵ ┻━┻" }

            it { is_expected.to be(false) }
          end

          context "when document_number is NOT valid against CiviCRM" do
            context "and does not find a contact" do
              before { stub_invalid_request_not_member }

              it { is_expected.to be(false) }
            end

            context "and contact has invalid membership name" do
              before { stub_invalid_request_not_militant }

              it { is_expected.to be(false) }
            end

            context "and contact has invalid membership status_id" do
              before { stub_invalid_request_was_member }

              it { is_expected.to be(false) }
            end

            context "and contact has invalid membership join_date" do
              before { stub_invalid_request_not_enough_seniority }

              it { is_expected.to be(false) }
            end
          end

          context "when document_number is valid against CiviCRM" do
            before { stub_valid_request }

            it { is_expected.to be(true) }
          end

          context "when it fails to connect to CiviCRM" do
            before { stub_invalid_request_connection_error }

            it { is_expected.to be(false) }
          end
        end

        describe "valid?" do
          subject { handler.valid? }

          context "when no user" do
            let(:user) { nil }

            it "raises an error" do
              expect { subject }.to raise_error(NoMethodError)
            end
          end

          context "when no document number" do
            let(:document_number) { nil }

            it { is_expected.to be(false) }
          end

          it_behaves_like "validate document_number against CiviCRM"
        end

        describe "document_valid?" do
          subject { handler.document_valid? }

          context "when no user" do
            let(:user) { nil }

            before { stub_valid_request }

            it "does NOT raise an error" do
              expect { subject }.not_to raise_error
            end
          end

          it_behaves_like "validate document_number against CiviCRM"
        end
      end
    end
  end
end
