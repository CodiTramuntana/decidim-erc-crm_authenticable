# frozen_string_literal: true

require "spec_helper"

describe "Erc::CrmAuthenticable", type: :system do
  let(:organization) { create(:organization, force_users_to_authenticate_before_access_organization: true) }

  before do
    switch_to_host(organization.host)
  end

  context "when the user visits the root path" do
    before do
      visit decidim.root_path
    end

    it "is redirected to the 'Sign in' page" do
      within ".flash.callout.warning" do
        expect(page).to have_content("Please, login with your account before access")
      end

      within "#session_new_user" do
        expect(page).to have_field("session_user_email", with: "")
        expect(page).to have_field("session_user_password", with: "")
        expect(page).to have_button("Log in")
      end
      expect(page).to have_link("Sign up")
    end
  end

  context "when the user signs in" do
    let!(:user) do
      create(
        :user,
        :confirmed,
        email: "john.doe@example.org",
        organization:,
        password: "ppasswordd",
        scope: create(:scope, organization:),
        extended_data: { document_number: Base64.strict_encode64("123456789A") }
      )
    end

    before do
      visit decidim.new_user_session_path
    end

    context "when it fails to connect the CiviCRM" do
      before do
        stub_invalid_request_connection_error
        within "#session_new_user" do
          fill_in :session_user_email, with: "john.doe@example.org"
          fill_in :session_user_password, with: "ppasswordd"
        end
        click_button "Log in"
      end

      it "does NOT allow to sign in" do
        expect(page).to have_css(".callout.alert", text: "It was not possible to connect with CiviCRM. Please try again later.")
      end
    end

    context "when the user IS a paying member of ERC" do
      before do
        stub_valid_request
        within "#session_new_user" do
          fill_in :session_user_email, with: "john.doe@example.org"
          fill_in :session_user_password, with: "ppasswordd"
        end
        click_button "Log in"
      end

      it "allows to sign in" do
        expect(page).to have_css(".callout.success", text: "Signed in successfully.")
      end
    end

    context "when the user is NOT a paying member of ERC" do
      before do
        stub_invalid_request_was_member
        within "#session_new_user" do
          fill_in :session_user_email, with: "john.doe@example.org"
          fill_in :session_user_password, with: "ppasswordd"
        end
        click_button "Log in"
      end

      it "does NOT allow to sign in" do
        expect(page).to have_css(".callout.alert", text: "Document number does not correspond to any dues-paying member of Esquerra Republicana.")
      end
    end
  end
end
