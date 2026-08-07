# rr-model

Part of the **RailsRuntimes** ecosystem. DATA YOURS, SOFTWARE MINE (proprietary-restrictive) — see LICENSE.

`rr-model` is the **portable model foundation**: a pure-Ruby DSL that compiles once to an immutable schema descriptor (fields, identity, associations, validations, sync policy). No Active Record, no SQLite, no browser APIs in Core.

**Pairs with:** `rr-crud` (consumes `Schema#column_hashes`), `rr-store` (persists records).

Ruby namespace: `RailsRuntimes::Model` (`require "rails_runtimes/model"` or `require "rr-model"`).

## Multi-store bindings (0.2)

```ruby
schema = RailsRuntimes::Model.define("Notes::Note", table: "notes") do
  field :id, type: :uuid, null: false, primary_key: true
  field :title, type: :string, null: false
  identity :id
  store surface: :server, table: "notes", driver_kind: :active_record
  store surface: :browser, table: "notes", driver_kind: :opfs_sqlite
end.value

schema.bindings            # => [Binding, Binding]
schema.binding_for(:server)
schema.graph_terms         # plain frozen [s,p,o] with urn:rr: IRIs (no RDF lib)
```

Logical identity stays `Notes::Note`. Route drivers by surface in `rr-store`.

## Status

`0.2.0` — portable core + multi-store bindings + graph provenance terms.

## Copyright

(c) 2026 CBI BUSINESS TRANSACTIONS, LLC. Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine. Licensed under DATA YOURS, SOFTWARE MINE (proprietary-restrictive) — see LICENSE.
