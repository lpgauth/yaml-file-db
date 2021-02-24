## YAML-DB

### Architecture
YAML File dabatase
Each directory under /db is a table in the database
Each file under /db/FOO is a row in the FOO table
The row identifier is filename minus the .yml extension
Filenames are expected to follow the dash-case naming convention
The row identifier uniqueness is garanteed by the filesytem
Each file is a valid YAML document
Each file is validated against a Rex schema in /schemas
Database is accessed via the singleton object SSOT::DB
Tables are accessible via accessors
Each table is a Hash where the key is the row identifier and the value is the object

### Usage
```ruby
require 'yaml-file-db'

db = YDB::Database.new("/path/to/db", "/path/to/schemas").build
```
