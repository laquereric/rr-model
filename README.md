# rr-model

Part of the **RailsRuntimes** ecosystem. Apache-2.0.

`rr-model` is the **portable model foundation**: a pure-Ruby DSL that compiles once to an immutable schema descriptor (fields, identity, associations, validations, sync policy). No Active Record, no SQLite, no browser APIs in Core.

**Pairs with:** `rr-crud` (consumes `Schema#column_hashes`), `rr-store` (persists records).

Ruby namespace: `RailsRuntimes::Model` (`require "rails_runtimes/model"` or `require "rr-model"`).

## Status

`0.1.0` — portable core.

## Copyright

(c) 2026 CBI BUSINESS TRANSACTIONS, LLC. Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine. Licensed under Apache-2.0.
