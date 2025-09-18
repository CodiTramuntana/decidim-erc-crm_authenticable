# Sign up through CSV

In order to sign up users, we need a csv with format:

```
DNI,nom,Email,Tmobil,codi

123456789A,Test User,user@example.org,650650650,5117
```

This fields are required for sign up. The last field, code, in this case the code 5117, belongs to a local scope. We don't know what code belongs to user and it is given to us in csv. This code must be the **local code** in hierarchy.

## Required CSVs (files)

To be able to generate code mapping, we need the following files:


### **scopes_codes.csv**

```
code,name,type

0002,Girona,FR
```

In this example, we have the code 0002 that belongs to Girona, which is a region.

### **scopes_hierarchy.csv**

```
FR,FC,SL

0002,5100,5117
```
In this example, we have relation between Girona's code and their local and comarcal codes. In this case, 5100 is the relate comarcal code and 5117 is the relate local code.

Legend:

**FR**: regional code
**FC**: comarcal code
**SL**: local code

## Rake tasks for run

Next step after having the files is executing the following rake tasks in order to generate required yml files.

The tasks must be run in this order:
```
rake erc_auth:csv_import:comarcals
rake erc_auth:csv_import:locals
rake erc_auth:csv_import:regionals 
rake erc_auth:csv_import:local_comarcal_relationships
rake erc_auth:csv_import:local_regional_relationships 
rake civi_crm:generate:comarcal_exceptions  
rake civi_crm:generate:decidim_scopes_mapping
rake civi_crm:create:scopes
```

## 1. rake erc_auth:csv_import:comarcals

This tasks generates the file `comarcals.yml` from `scopes_codes.csv`.

Checks the rows in `scopes_codes.csv` that have FC code and adds them to `comarcals.yml`.

`comarcals.yml` contain:

```
---
'0100': Alacantí
'0200': Alcalatén
'0300': Alcoià
'0400': Alt Camp
'0500': Alt Empordà
'0600': Alt Maestrat
```

## 2. rake erc_auth:csv_import:locals

This task generates the file `locals.yml` from `scopes_codes.csv`.

Checks the rows in `scopes_codes.csv` that have SL code and adds them to `locals.yml`.

`locals.yml` contains:

```
---
'0103': Alacant
'0106': Mutxamel
'0110': Xixona
'0201': L'Alcora
'0301': Alcoi
'0402': Alcover
```

## 3. rake erc_auth:csv_import:regionals 

This tasks generates the file `regionals.yml` from `scopes_codes.csv`.

Checks the rows in `scopes_codes.csv` that have FR code and adds them to `regionals.yml`.

`regionals.yml` contains:

```
---
'0001': Regió Metropolitana de Barcelona
'0002': Girona
'0003': Camp de Tarragona
'0004': Ebre
```

## 4. rake erc_auth:csv_import:local_comarcal_relationships

This task generates the file `local_comarcal_relationships.yml` from the files `locals.yml`, `comarcals.yml` and `scopes_hierarchy.csv`.

`comarcals.yml` is loaded but it seems that it is not being used.

The task iterates `locals.yml` and, for each row, it searches for the SL code in `scopes_hierarchy.csv` and takes the  FC (comarcal) code. Once the correspondence is resolved it is saved in the output `local_comarcal_relationships.yml` file.

`local_comarcal_relationships.yml` contains:

```
---
'0103': '0100'
'0106': '0100'
'0110': '0100'
'0201': '0200'
'0301': '0300'
```

## 5. rake erc_auth:csv_import:local_regional_relationships

This rake generates the file `local_regional_relationships.yml` from files `locals.yml`, `regionals.yml` and `scopes_hierarchy.csv`.

`regionals.yml` is loaded but it seems that it is not being used.

The task iterates `locals.yml` and, for each row, it searches for the SL code in `scopes_hierarchy.csv` and takes the  FR (regional) code. Once the correspondence is resolved it is saved in the output `local_regional_relationships.yml` file.

`local_regional_relationships.yml` contains:

```
---
'0103': '0010'
'0106': '0010'
'0110': '0010'
'0201': '0010'
'0301': '0010'
```


## 6. rake civi_crm:generate:comarcal_exceptions  

This rake generate the file `comarcal_exceptions.yml` from file `comarcals.yml` and the codes defined in the constant `Decidim::Erc::CrmAuthenticable::CIVICRM_COMARCAL_EXCEPTIONS`. This constant is in app in `config/initializers/decidim_erc_crm_authenticable.rb`

```
Decidim::Erc::CrmAuthenticable::CIVICRM_COMARCAL_EXCEPTIONS = %w(
  9300
  2100
  5600
  9200
  9900
).freeze
```
This codes are comarcal codes 'acting' like locals. The relationship is make between this codes and file `comarcals.yml`.


`comarcal_exceptions.yml` contains:

```
---
'2100': Baix Llobregat
'5600': Baix Besòs - Maresme
```

## 7. rake civi_crm:generate:decidim_scopes_mapping

This task generate the file `decidim_scopes_mapping.yml` from files `comarcal_exceptions.yml`, `local_comarcal_relationships.yml` and `local_regional_relationships.yml`.

This file is used on user registration. For that, the code on the left in file is the local scope code in the csv users. The code on the right is a code field in a scope in Decidim.

Use case:

An user has 0103 code in csv users -> this code is associated with 0010 in file `decidim_scopes_mapping.yml` -> so 0010 should belong to the `code` field of scope in Decidim -> user registered successfully!

`decidim_scopes_mapping.yml` contains:

```
---
'0103': '0010'
'0106': '0010'
'0110': '0010'
'0201': '0010'
'0301': '0010'
'0402': '0003'
'0404': '0003'
```

## 8. rake civi_crm:create:scopes 

This task create the scopes in Decidim from files `comarcal_exceptions.yml` and `regionals.yml`. 

For each file, the task create the scopes in both files.

For example:

comarcal_exceptions: 
```
---
'2100': Baix Llobregat
```

regionals:
```
'0002': Girona
```
In Decidim, two scopes will be created, one with code 2100 and name Baix Llobregat, and the other with code 0002 and the name Girona.
