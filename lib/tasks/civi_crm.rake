# frozen_string_literal: true
require 'csv'

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
      raise "Failed to get the data from CiviCRM!" if response[:error]

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

  namespace :import_by_csv do
    task all: [:comarcals, :regionals, :locals, :local_comarcal_relationships, :local_regional_relationships]

    desc "Generates a YAML file with the CSV with 'Comarcal' tag"
    task comarcals: :environment do
      csv_text = File.read('tmp/scopes_codes.csv')
      csv = CSV.parse(csv_text, headers: true)
      
      csv = csv.select { |row| row['type'] == 'FC' }
      csv = csv.map { |row| row.to_h }

      result = get_code_and_display_name(csv)
      write_config_yaml!('comarcals', result)
    end

    desc "Generates a YAML file with the CSV with 'Regional' tag"
    task regionals: :environment do
      csv_text = File.read('tmp/scopes_codes.csv')
      csv = CSV.parse(csv_text, headers: true)
      
      csv = csv.select { |row| row['type'] == 'FR' }
      csv = csv.map { |row| row.to_h }

      result = get_code_and_display_name(csv)
      write_config_yaml!('regionals', result)
    end

    desc "Generates a YAML file with the CSV with 'Locals' tag"
    task locals: :environment do
      csv_text = File.read('tmp/scopes_codes.csv')
      csv = CSV.parse(csv_text, headers: true)
      
      csv = csv.select { |row| row['type'] == 'SL' }
      csv = csv.map { |row| row.to_h }

      result = get_code_and_display_name(csv)
      write_config_yaml!('locals', result)
    end

    desc "Generates a YAML file with the relationship between CSV 'Local' and 'Comarcal'"
    task local_comarcal_relationships: :environment do
      local_ids = load_config_yaml("locals").keys
      comarcal_ids = load_config_yaml("comarcals").keys
      result = get_code_relationships(local_ids, comarcal_ids, 'comarcal')
      write_config_yaml!("local_comarcal_relationships", result)
    end

    desc "Generates a YAML file with the relationship between CSV 'Local' and 'Regional'"
    task local_regional_relationships: :environment do
      local_ids = load_config_yaml("locals").keys
      regional_ids = load_config_yaml("regionals").keys
      result = get_code_relationships(local_ids, regional_ids, 'regional')
      write_config_yaml!("local_regional_relationships", result)
    end

    def get_code_and_display_name(body)
      body.map! { |element| { element['code'] => element['name'] } }.reduce(Hash.new, :merge)
    end

    def get_code_relationships(local_ids, filter_ids, scope_type)
      local_ids.each_with_object({}) do |element, memo|
        csv_text = File.read('tmp/scopes_hierarchy.csv')
        csv = CSV.parse(csv_text, headers: true)

        csv = csv.select { |row| row["SL"] == element }.first.to_h
        next unless csv.present?

        memo[csv['SL']] = csv["FC"] if scope_type == 'comarcal'
        memo[csv['SL']] = csv["FR"] if scope_type == 'regional'
      end
    end
  end

  namespace :generate do
    task all: [:comarcal_exceptions, :decidim_scopes_mapping]

    desc "Generates a YAML file with filtered CiviCRM Contacts of type 'Organization' and sub_type 'Comarcal'"
    task comarcal_exceptions: :environment do
      comarcals = load_config_yaml("comarcals")
      result = comarcals.select { |id, _name| comarcal_exception_ids.include?(id) }
      raise "Comarcal exceptions not found!" unless result.size == comarcal_exception_ids.size

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

    def comarcal_exception_ids
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
        scope= Decidim::Scope.find_or_initialize_by(
          organization: organization,
          code: contact_id
        )
        scope.name= { "ca" => scope_name, "en" => scope_name, "es" => scope_name }
        scope.save!
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
