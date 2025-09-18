# frozen_string_literal: true

require "spec_helper"

describe "Registration", type: :system do
  let(:organization) { create(:organization, force_users_to_authenticate_before_access_organization: true) }
  let!(:scope) { create(:scope, organization:, code: "custom_21") }

  before do
    switch_to_host(organization.host)

    Rails.application.secrets
  end

  context "when the user signs up" do
    before do
      visit decidim.new_user_registration_path
    end

    it "is shown the 'Verify your identity document' page" do
      expect(page).to have_css("h1", text: "Verify your identity document")
      within "#register-form-step-1" do
        expect(page).to have_field("user_document_number")
      end
      expect(page).to have_button("Request verification", visible: :all)
    end

    context "when the 'Identity document form' is filled with valid data" do
      before do
        stub_valid_request
        within "#register-form-step-1" do
          fill_in :user_document_number, with: "123456789A"
        end
        click_button "Request verification", visible: :all
      end

      it "redirects to the 'Registration' page" do
        expect(page).to have_css("h1", text: "Sign up")
        expect(page).to have_button("Sign up")
      end

      it "prefilles the 'Registration form' with data from CiviCRM" do
        within "#register-form-step-2" do
          # Data returned from CiviCRM should be readonly and users must be informed.
          expect(page).to have_tag("div.callout.announcement", text: /administracio@esquerra.cat/)
          expect(page).to have_field("user_name", with: "John Doe", readonly: true)
          expect(page).to have_field("user_nickname", with: "JD", readonly: true)
          expect(page).to have_field("user_email", with: "john.doe@example.org", readonly: true)
          expect(page).to have_field("user_phone_number", with: "666-666-666", readonly: true)
          expect(page).to have_field("user_password", with: "")
        end
      end

      context "when the 'Registration form' is filled with valid data and show newsletter modal" do
        before do
          within "#register-form-step-2" do
            fill_in :user_password, with: "rPYWYKQJrXm97b4ytswc"
            check :user_tos_agreement
          end
          click_button "Sign up"
        end

        it "registers the user" do
          expect(page).to have_css(".callout.success", text: "You have signed up successfully.")
        end

        context "when the 'Identity document form' is filled with USED data" do
          before do
            visit decidim.new_user_registration_path
            stub_valid_request
            within "#register-form-step-1" do
              fill_in :user_document_number, with: "123456789A"
            end
            click_button "Request verification", visible: :all
          end

          it "does NOT redirect to the decidim 'Registration' page" do
            expect(page).not_to have_css("h1", text: "Sign up")
            within "label[for='user_document_number']" do
              expect(page).to have_css(".form-error", text: "There is already a user registered with this data.")
            end
          end
        end
      end

      context "when the 'Registration form' is filled with valid data and not show newsletter modal" do
        before do
          within "#register-form-step-2" do
            fill_in :user_password, with: "rPYWYKQJrXm97b4ytswc"
            check :user_tos_agreement
          end
          click_button "Sign up"
        end

        it "newsletter modal not show" do
          expect(page).not_to have_css("#sign-up-newsletter-modal")
        end

        it "registers the user" do
          expect(page).to have_css(".callout.success", text: "You have signed up successfully.")
        end

        context "when the 'Identity document form' is filled with USED data" do
          before do
            visit decidim.new_user_registration_path
            stub_valid_request
            within "#register-form-step-1" do
              fill_in :user_document_number, with: "123456789A"
            end
            click_button "Request verification", visible: :all
          end

          it "does NOT redirect to the decidim 'Registration' page" do
            expect(page).not_to have_css("h1", text: "Sign up")
            within "label[for='user_document_number']" do
              expect(page).to have_css(".form-error", text: "There is already a user registered with this data.")
            end
          end
        end
      end
    end

    context "when the 'Identity document form' is filled with invalid data" do
      context "and the document number is in wrong format" do
        before do
          stub_invalid_request_not_member
          within "#register-form-step-1" do
            fill_in :user_document_number, with: "(╯°□°）╯︵ ┻━┻"
          end
          click_button "Request verification", visible: :all
        end

        it "does NOT redirect to the 'Registration' page" do
          expect(page).not_to have_css("h1", text: "Sign up")
          within "label[for='user_document_number']" do
            expect(page).to have_css(".form-error", text: "must be all uppercase and contain only letters and/or numbers")
          end
        end
      end

      context "and the user is not a member of ERC" do
        before do
          stub_invalid_request_not_member
          within "#register-form-step-1" do
            fill_in :user_document_number, with: "123456789A"
          end
          click_button "Request verification", visible: :all
        end

        it "does NOT redirect to the decidim 'Registration' page" do
          expect(page).not_to have_css("h1", text: "Sign up")
          within "label[for='user_document_number']" do
            expect(page).to have_css(".form-error", text: "does not correspond to any dues-paying member of Esquerra Republicana.")
          end
        end
      end

      context "and the user is not a paying member of ERC" do
        before do
          stub_invalid_request_was_member
          within "#register-form-step-1" do
            fill_in :user_document_number, with: "123456789A"
          end
          click_button "Request verification", visible: :all
        end

        it "does NOT redirect to the decidim 'Registration' page" do
          expect(page).not_to have_css("h1", text: "Sign up")
          within "label[for='user_document_number']" do
            expect(page).to have_css(".form-error", text: "does not correspond to any dues-paying member of Esquerra Republicana.")
          end
        end
      end
    end

    context "when the 'Identity document form' fails to connect the CiviCRM" do
      before do
        stub_invalid_request_connection_error
        within "#register-form-step-1" do
          fill_in :user_document_number, with: "123456789A"
        end
        click_button "Request verification", visible: :all
      end

      it "does NOT redirect to the decidim 'Registration' page" do
        expect(page).not_to have_css("h1", text: "Sign up")
        expect(page).to have_css(".callout.alert", text: "It was not possible to connect with CiviCRM. Please try again later.")
      end
    end
  end
end
