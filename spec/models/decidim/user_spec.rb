# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe User do
    subject { user }

    let(:handler_name) { Decidim::Erc::CrmAuthenticable::CrmAuthenticableAuthorizationHandler.handler_name }
    let(:organization) { create(:organization, available_authorizations: [handler_name]) }
    let(:scope) { create(:scope, organization:) }
    let(:user) { create(:user, admin:, scope:, organization:, extended_data:) }
    let(:admin) { false }
    let(:extended_data) { { "document_number" => Base64.strict_encode64("123456789A") } }

    it { is_expected.to be_valid }

    describe "validations" do
      subject { user.valid? }

      context "with scope" do
        it { is_expected.to be(true) }
      end

      context "without scope" do
        let(:scope) { nil }

        context "when user is admin" do
          let(:admin) { true }

          it { is_expected.to be(true) }
        end

        context "when user is NOT admin (default)" do
          it "raises an error" do
            expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

      context "with a nickname made of initials" do
        before { user.nickname = user.name.split.map { |w| w.chars.first }.join }

        it { is_expected.to be(true) }
      end
    end

    describe "crm_authorized?" do
      subject { user.crm_authorized? }

      context "when the user is NOT authorized" do
        it { is_expected.to be(false) }
      end

      context "when the user is authorized" do
        before do
          create(:authorization, name: handler_name, user:, granted_at: 1.day.ago)
        end

        it { is_expected.to be(true) }
      end
    end

    describe "crm_authorize!" do
      subject { user.crm_authorize! }

      context "when extended_data does not contain a document_number" do
        let(:extended_data) { {} }
        let(:error) { "Document number can't be blank" }

        before { stub_invalid_request_not_member }

        it { is_expected.to include(authorized: false, error:) }
      end

      context "when document_number NOT is valid against CiviCRM" do
        let(:error) { "Document number does not correspond to any dues-paying member of Esquerra Republicana." }

        before { stub_invalid_request_not_member }

        it { is_expected.to include(authorized: false, error:) }
      end

      context "when document_number is valid against CiviCRM" do
        before { stub_valid_request }

        it { is_expected.to include(authorized: true) }
      end

      context "when it fails to connect to CiviCRM" do
        let(:error) { "It was not possible to connect with CiviCRM. Please try again later." }

        before { stub_invalid_request_connection_error }

        it { is_expected.to include(authorized: false, error:) }
      end
    end
  end
end
