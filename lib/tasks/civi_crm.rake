# frozen_string_literal: true

namespace :civi_crm do
  task init: ["import:all", "generate:all", "create:scopes"]

  namespace :import do
    task all: [:comarcals, :regionals, :local_comarcal_relationships, :local_regional_relationships]

    desc "Generates a YAML file with the CiviCRM Contacts of type 'Organization' and sub_type 'Comarcal'"
    task comarcals: :environment do
      data = get_civi_crm_data(:find_organizations, ["Comarcal"])
      result = get_contact_id_and_display_name(data)
      write_config_yaml!("comarcals", result)
    end

    desc "Generates a YAML file with the CiviCRM Contacts of type 'Organization' and sub_type 'Regional'"
    task regionals: :environment do
      data = get_civi_crm_data(:find_organizations, ["Regional"])
      result = get_contact_id_and_display_name(data)
      write_config_yaml!("regionals", result)
    end

    desc "Generates a YAML file with the relationship between CiviCRM Contacts of sub_type 'Local' and sub_type 'Comarcal'"
    task local_comarcal_relationships: :environment do
      data = get_civi_crm_data(:find_local_organization_relationships)
      comarcal_ids = load_config_yaml("comarcals").keys
      result = get_contact_id_relationships(data, comarcal_ids)
      write_config_yaml!("local_comarcal_relationships", result)
    end

    desc "Generates a YAML file with the relationship between CiviCRM Contacts of sub_type 'Local' and sub_type 'Regional'"
    task local_regional_relationships: :environment do
      data = get_civi_crm_data(:find_local_organization_relationships)
      regional_ids = load_config_yaml("regionals").keys
      result = get_contact_id_relationships(data, regional_ids)
      write_config_yaml!("local_regional_relationships", result)
    end

    def get_civi_crm_data(method_name, parameters_array = [])
      client = Decidim::Erc::CrmAuthenticable::CiviCrmClient.new
      response = client.send(method_name, *parameters_array)
      raise "Failed to fetch the data" if response[:error]

      response[:body]
    end

    def get_contact_id_and_display_name(body)
      body.each_with_object({}) do |element, memo|
        next unless element["contact_is_deleted"].to_i.zero?

        memo[element["contact_id"]] = element["display_name"]
      end
    end

    def get_contact_id_relationships(body, filter_ids)
      body.each_with_object({}) do |element, memo|
        next unless element["contact_is_deleted"].to_i.zero?
        next unless (relationships = element["api.Relationship.get"]["values"]).any?
        next unless (relationship = relationships.find { |r| r["contact_id_b"].in?(filter_ids) })

        memo[element["contact_id"]] = relationship["contact_id_b"]
      end
    end
  end

  namespace :generate do
    task all: [:comarcal_exceptions, :decidim_scopes_mapping]

    desc "Generates a YAML file with filtered CiviCRM Contacts of type 'Organization' and sub_type 'Comarcal'"
    task comarcal_exceptions: :environment do
      comarcals = load_config_yaml("comarcals")
      result = comarcals.select { |_id, name| comarcal_exception_names.include?(name) }
      raise "Comarcals not found" unless result.size == comarcal_exception_names.size

      write_config_yaml!("comarcal_exceptions", result)
    end

    desc "Generates a YAML file with the relationship between CiviCRM Contacts of sub_type 'Local' and sub_type 'Comarcal' or 'Regional'"
    task decidim_scopes_mapping: :environment do
      comarcal_exception_ids = load_config_yaml("comarcal_exceptions").keys
      local_comarcal_rel = load_config_yaml("local_comarcal_relationships")
      local_regional_rel = load_config_yaml("local_regional_relationships")

      local_exception_ids = local_comarcal_rel.each_with_object([]) do |(local_id, comarcal_id), arr|
        arr << local_id if comarcal_exception_ids.include?(comarcal_id)
      end

      result = local_regional_rel.each_with_object({}) do |(local_id, regional_id), hsh|
        hsh[local_id] = local_exception_ids.include?(local_id) ? local_comarcal_rel[local_id] : regional_id
      end

      write_config_yaml!("decidim_scopes_mapping", result)
    end

    def comarcal_exception_names
      Decidim::Erc::CrmAuthenticable::CIVICRM_COMARCAL_EXCEPTIONS
    end
  end

  namespace :create do
    desc "Creates `Decidim::Scope`s from the CiviCRM Contacts of type 'Organization' and sub_type 'Comarcal'"
    task scopes: :environment do
      next unless (organization = Decidim::Organization.first)

      comarcals = load_config_yaml("comarcal_exceptions")
      create_scopes_from_contacts!(comarcals, organization)
      regionals = load_config_yaml("regionals")
      create_scopes_from_contacts!(regionals, organization)
      puts "All `Decidim::Scope`s are in place"
    end

    def create_scopes_from_contacts!(contacts, organization)
      contacts.each do |contact_id, display_name|
        next if display_name[/\d/]

        scope_name = display_name.strip
        Decidim::Scope.find_or_create_by!(
          organization: organization,
          name: { "ca" => scope_name, "en" => scope_name, "es" => scope_name },
          code: contact_id
        )
      end
    end
  end

  def write_config_yaml!(filename, content)
    File.write(filepath(filename), content.to_yaml)
    puts "File generated 'config/civi_crm/#{filename}.yml'"
  end

  def filepath(filename)
    Dir.mkdir("config/civi_crm") unless File.directory?("config/civi_crm")
    Rails.root.join("config", "civi_crm", "#{filename}.yml").to_s
  end

  def load_config_yaml(filename)
    YAML.load_file(filepath(filename))
  end
end
