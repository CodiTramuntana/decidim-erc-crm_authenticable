# Decidim::Erc::CrmAuthenticable

The gem has been developed by [CodiTramuntana](https://coditramuntana.com).

`Decidim::Erc::CrmAuthenticable` is a [Decidim](https://github.com/decidim/decidim) module that does mainly three things:
- Customizes the login and signup process of the application.
- Implements a custom verification method against the CiviCrm of Esquerra Republicana (based on the [Decidim::Verifications](https://github.com/decidim/decidim/tree/master/decidim-verifications#decidimverifications) module) that is used in both login and signup.
- Adds a `belongs_to` association between the `Decidim::User` and `Decidim::Scope` models and assigns a scope to each user during registration representing their comarcal Esquerra Republicana organization.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'decidim-erc-crm_authenticable'
```

And then execute:

```bash
$ bundle
$ bundle exec rails decidim_erc_crm_authenticable:install:migrations
$ bundle exec rails db:migrate
```

And then set the configuration values needed to perform requests to CiviCRM in `config/secrets.yml`:

```yml
erc_crm_authenticable:
  api_base: <%= ENV["CIVICRM_API_BASE"] %>
  site_key: <%= ENV["CIVICRM_SITE_KEY"] %>
  api_key: <%= ENV["CIVICRM_API_KEY"] %>
  secret_key: <%= ENV["ERC_SECRET_KEY"] %>
```

Finally run the following rake task:

```bash
$ bundle exec rake civi_crm:init
```
This task generates the mapping that makes possible to find a `Decidim::Scope` by their `#code` using the information that is returned by CiviCRM.

## How it works

This module has been initially designed to perform authentication against CiviCRM but it also supports authentication against a CSV file as an alternative. To enable this second option (instead of authenticating against the CRM) set the path to the file in `config/secrets.yml`:

```yml
erc_crm_authenticable:
  users_csv_path: <%= ENV["ERC_USERS_CSV_PATH"] %>
```

### Registration
- The user needs to validate their DNI against CiviCRM to be able to register to the application.
- The user is then redirected to the registration form prefilled with their personal data found in CiviCRM.
- The user is created with the following information stored in the `extended_data` `Hash`:
  - `phone_number`: Base64-encoded version of their phone number (if leaved filled during registration).
  - `member_of_code`: CiviCRM Contact ID of their local Esquerra Republicana organization.
  - `document_number`: Base64-encoded version of their identity document number (for further requests).
- The user is assigned a scope based on their `member_of_code` (See [Installation](#installation)).

### Login
- After every login, users are validated against CiviCRM to check if they are dues-paying members of Esquerra Republicana; if not, they are logged out.
- If they are succesfully validated a `Decidim::Authorization` is created or updated for the user; else, their authorization is deleted.

### Verification options
These options can be set in the admin zone to alter the authorization logic related to a component action:
- Type of membership: (1) militant, (2) sympathizer, (3) friend
- Required membership seniority: dd/mm/yyy

## Testing

Run the following in the gem development path to create the test app:

```bash
$ bundle
$ bundle exec rake test_app
$ cd spec/decidim_dummy_app/
$ bundle exec rails decidim_erc_crm_authenticable:install:migrations
$ RAILS_ENV=test bundle exec rails db:migrate
$ bundle exec rake civi_crm:configure_secrets
```
Note that the database user has to have rights to create and drop a database in order to create the dummy test app database.

And the `civi_crm:configure_secrets` taks set the configuration values for the test app in `spec/decidim_dummy_app/config/secrets.yml` as:

```yaml
erc_crm_authenticable:
  api_base: https://api.base/?
  site_key: site_key
  api_key: api_key
  secret_key: secret_key
```
Note that the test stubs are configured to use the above values as to not reveal the real ones.

Finally to run the tests execute:

```bash
$ bundle exec rspec
```

## Versioning

`Decidim::Erc::CrmAuthenticable` depends directly on `Decidim::Core` in `0.19.0` version.

## License

This engine is distributed under the GNU AFFERO GENERAL PUBLIC LICENSE.
