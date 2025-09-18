# frozen_string_literal: true

require "spec_helper"
require "rake"

describe "civi_crm" do
  let(:invoke_task) do
    Rake::Task[task].reenable
    Rake.application.invoke_task(task)
  end

  before do
    Rake.application.rake_require "tasks/civi_crm"
    Rake::Task.define_task(:environment)
    allow($stdout).to receive(:puts)
    allow(File).to receive(:write)
  end

  describe "import" do
    let(:civi_crm_client) { Decidim::Erc::CrmAuthenticable::CiviCrmClient.new }
    let(:response) do
      {
        error: false,
        body:
      }
    end

    before do
      allow(Decidim::Erc::CrmAuthenticable::CiviCrmClient).to receive(:new).and_return(civi_crm_client)
    end

    shared_examples "raises an error when CiviCRM request fails" do
      let(:response) do
        {
          error: true,
          body: []
        }
      end

      it "raises an error when does not find the data in CiviCRM" do
        expect { invoke_task }.to raise_error(RuntimeError, "Failed to get the data from CiviCRM!")
      end
    end

    describe "comarcals" do
      let(:task) { "civi_crm:import:comarcals" }
      let(:body) do
        [
          {
            "contact_is_deleted" => "0",
            "contact_id" => "4",
            "display_name" => "Vallès Oriental (comarcal)"
          }
        ]
      end

      before do
        allow(civi_crm_client).to receive(:find_organizations).with("Comarcal").and_return(response)
      end

      it "creates a YAML file with comarcals in it" do
        expect(File).to receive(:write).with(
          %r{config/civi_crm/comarcals.yml},
          /'4': Vallès Oriental \(comarcal\)/
        )

        invoke_task
      end

      it_behaves_like "raises an error when CiviCRM request fails"
    end

    describe "regionals" do
      let(:task) { "civi_crm:import:regionals" }
      let(:body) do
        [
          {
            "contact_is_deleted" => "0",
            "contact_id" => "5827",
            "display_name" => "Barcelona (regional)"
          }
        ]
      end

      before do
        allow(civi_crm_client).to receive(:find_organizations).with("Regional").and_return(response)
      end

      it "creates a YAML file with regionals in it" do
        expect(File).to receive(:write).with(
          %r{config/civi_crm/regionals.yml},
          /'5827': Barcelona \(regional\)/
        )

        invoke_task
      end

      it_behaves_like "raises an error when CiviCRM request fails"
    end

    describe "local_comarcal_relationships" do
      let(:task) { "civi_crm:import:local_comarcal_relationships" }
      let(:body) do
        [
          {
            "contact_is_deleted" => "0",
            "contact_id" => "1",
            "api.Relationship.get" => { "values" => [{ "contact_id_b" => "4" }] }
          }
        ]
      end

      before do
        allow(civi_crm_client).to receive(:find_local_organization_relationships).and_return(response)
        allow(YAML).to receive(:load_file).and_return(double(keys: ["4"]))
      end

      it "creates a YAML file with local_comarcal_relationships in it" do
        expect(File).to receive(:write).with(
          %r{config/civi_crm/local_comarcal_relationships.yml},
          /'1': '4'/
        )

        invoke_task
      end

      it_behaves_like "raises an error when CiviCRM request fails"
    end

    describe "local_regional_relationships" do
      let(:task) { "civi_crm:import:local_regional_relationships" }
      let(:body) do
        [
          {
            "contact_is_deleted" => "0",
            "contact_id" => "1",
            "api.Relationship.get" => { "values" => [{ "contact_id_b" => "5827" }] }
          }
        ]
      end

      before do
        allow(civi_crm_client).to receive(:find_local_organization_relationships).and_return(response)
        allow(YAML).to receive(:load_file).and_return(double(keys: ["5827"]))
      end

      it "creates a YAML file with local_comarcal_relationships in it" do
        expect(File).to receive(:write).with(
          %r{config/civi_crm/local_regional_relationships.yml},
          /'1': '5827'/
        )

        invoke_task
      end

      it_behaves_like "raises an error when CiviCRM request fails"
    end
  end

  describe "generate" do
    describe "comarcal_exceptions" do
      let(:task) { "civi_crm:generate:comarcal_exceptions" }
      let(:comarcals) do
        {
          "4" => "Vallès Oriental (comarcal)",
          "1928" => "Esquerra Maresme",
          "1954" => "Alt Penedès (comarcal)"
        }
      end

      before do
        stub_const("Decidim::Erc::CrmAuthenticable::CIVICRM_COMARCAL_EXCEPTIONS", comarcal_exception_ids)
        allow(YAML).to receive(:load_file).and_return(comarcals)
      end

      context "when it finds all exceptions to filter" do
        let(:comarcal_exception_ids) { ["4"] }

        it "creates a YAML file with comarcal_exceptions in it" do
          expect(File).to receive(:write).with(
            %r{config/civi_crm/comarcal_exceptions.yml},
            "---\n'4': Vallès Oriental (comarcal)\n" # Exact match
          )

          invoke_task
        end
      end

      context "when it does NOT find all exceptions to filter" do
        let(:comarcal_exception_ids) { %w(4 12345679) }

        it "raises an error" do
          expect { invoke_task }.to raise_error(RuntimeError, "Comarcal exceptions not found!")
        end
      end
    end

    describe "decidim_scopes_mapping" do
      let(:task) { "civi_crm:generate:decidim_scopes_mapping" }
      let(:comarcal_exceptions) do
        { "4" => "Vallès Oriental (comarcal)" }
      end
      let(:local_comarcal_rel) do
        { "1" => "4" }
      end
      let(:local_regional_rel) do
        {
          "1" => "5827",
          "2" => "3"
        }
      end

      before do
        allow(YAML).to receive(:load_file).with(%r{config/civi_crm/comarcal_exceptions.yml}).and_return(comarcal_exceptions)
        allow(YAML).to receive(:load_file).with(%r{config/civi_crm/local_comarcal_relationships.yml}).and_return(local_comarcal_rel)
        allow(YAML).to receive(:load_file).with(%r{config/civi_crm/local_regional_relationships.yml}).and_return(local_regional_rel)
      end

      it "creates a YAML file with decidim_scopes_mapping in it" do
        expect(File).to receive(:write).with(
          %r{config/civi_crm/decidim_scopes_mapping.yml},
          "---\n'1': '4'\n'2': '3'\n" # Exact match
        )

        invoke_task
      end
    end
  end

  describe "create:scopes" do
    let(:task) { "civi_crm:create:scopes" }
    let(:comarcals) do
      {
        "4" => "Vallès Oriental (comarcal)",
        "1928" => "Esquerra Maresme",
        "1954" => "Alt Penedès (comarcal)"
      }
    end

    context "with organization" do
      before do
        allow(YAML).to receive(:load_file).and_return(comarcals)
        # Creating Organization manually as I'm having troubles with Faker translations.
        Decidim::Organization.create!(
          name: "Kohler-Moen",
          host: "1.lvh.me",
          default_locale: "en",
          available_locales: ["en"],
          reference_prefix: "DDS",
          enable_omnipresent_banner: false,
          highlighted_content_banner_enabled: false,
          badges_enabled: true,
          send_welcome_notification: true,
          users_registration_mode: "enabled",
          user_groups_enabled: true
        )
      end

      it "creates Scopes and assign the correct codes" do
        expect { invoke_task }.to change(Decidim::Scope, :count).by(3)
        codes = Decidim::Scope.pluck(:code)
        expect(codes).to include("4", "1928", "1954")
      end
    end

    context "without organization" do
      it "does not create Scopes" do
        expect { invoke_task }.not_to change(Decidim::Scope, :count)
      end
    end
  end
end
