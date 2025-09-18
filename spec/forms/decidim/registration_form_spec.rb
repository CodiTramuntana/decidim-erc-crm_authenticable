# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe RegistrationForm do
    subject { form }

    let(:form) do
      described_class.from_params(params).with_context(current_organization: create(:organization))
    end
    let(:params) do
      {
        name: "User",
        nickname: "justme",
        email: "user@example.org",
        password: "S4CGQ9AM4ttJdPKS",
        tos_agreement: "1",
        phone_number:,
        document_number: Base64.strict_encode64("123456789A"),
        member_of_code: "custom_21"
      }
    end
    let(:phone_number) { "666-666-666" }

    it { is_expected.to be_valid }

    describe "validations" do
      context "without phone_number" do
        before { form.phone_number = nil }

        it { is_expected.to be_valid }
      end

      context "without document_number" do
        before { form.document_number = nil }

        it { is_expected.to be_invalid }
      end

      context "without member_of_code" do
        before { form.member_of_code = nil }

        it { is_expected.to be_invalid }
      end
    end

    describe "extended_data" do
      subject { form.extended_data }

      it { is_expected.to be_a(Hash) }
      it { is_expected.to include(params.slice(:document_number, :member_of_code)) }
      it { is_expected.to include(phone_number: Base64.strict_encode64(phone_number)) }

      context "without phone_number" do
        before { form.phone_number = nil }

        it { is_expected.to include(phone_number: "") }
      end
    end
  end
end
