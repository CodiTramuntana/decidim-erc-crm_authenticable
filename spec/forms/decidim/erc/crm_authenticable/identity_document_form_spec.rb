# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Erc
    module CrmAuthenticable
      describe IdentityDocumentForm do
        let(:form) do
          described_class.from_params(document_number:).with_context(context)
        end

        let(:organization) { create(:organization) }
        let(:context) { { current_organization: organization } }
        let(:document_number) { "123456789A" }

        describe "valid?" do
          subject { form.valid? }

          context "when document_number NOT present" do
            let(:document_number) { nil }

            it { is_expected.to be(false) }
          end

          context "when document_number NOT is valid against CiviCRM" do
            before { stub_invalid_request_not_member }

            it { is_expected.to be(false) }
          end

          context "when document_number is valid against CiviCRM" do
            before { stub_valid_request }

            it { is_expected.to be(true) }
          end

          context "when it fails to connect to CiviCRM" do
            before { stub_invalid_request_connection_error }

            it { is_expected.to be(false) }
          end

          context "when a user is already registered with a document_number" do
            before do
              create(:user,
                     organization:,
                     scope: create(:scope, organization:),
                     extended_data: { document_number: Base64.strict_encode64("123456789A") })
              stub_valid_request
            end

            it { is_expected.to be(false) }
          end
        end

        describe "registration_form_params" do
          subject { form.registration_form_params }

          context "when form has not been validated yet" do
            it { is_expected.to be_empty }
          end

          context "when document_number is valid against CiviCRM" do
            let(:user_data) do
              {
                name: "John Doe",
                nickname: "JD",
                email: a_kind_of(String),
                phone_number: a_kind_of(String),
                document_number: Base64.strict_encode64(document_number),
                member_of_code: a_kind_of(String)
              }
            end

            before do
              stub_valid_request
              form.validate
            end

            it { is_expected.to include(user_data) }
          end

          context "when a user is already registered with the same nickname" do
            before do
              create(:user,
                     nickname: "JD",
                     organization:,
                     scope: create(:scope, organization:))
              stub_valid_request
              form.validate
            end

            it { is_expected.to include(nickname: "JD_2") }
          end

          context "when a user's initials has accents" do
            let(:user_data) { { "display_name" => "Name with Áccents" } }

            before do
              stub_valid_request
              form.validate
              # rubocop:disable RSpec/AnyInstance
              allow_any_instance_of(described_class).to receive(:user_data).and_return(user_data)
              # rubocop:enable RSpec/AnyInstance
            end

            it { is_expected.to include(nickname: "NwA") }
          end

          context "when document_number NOT is valid against CiviCRM" do
            before do
              stub_invalid_request_not_member
              form.validate
            end

            it { is_expected.to be_empty }
          end

          context "when it fails to connect to CiviCRM" do
            before do
              stub_invalid_request_connection_error
              form.validate
            end

            it { is_expected.to be_empty }
          end
        end
      end
    end
  end
end
