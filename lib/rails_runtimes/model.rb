# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "model/version"
require_relative "model/outcome"
require_relative "model/types"
require_relative "model/identity"
require_relative "model/schema"
require_relative "model/definition"
require_relative "model/validator"
require_relative "model/entity"
require_relative "model/registry"

# Pure portable model surface: DSL → immutable schema descriptor.
# No Active Record / SQLite / browser deps. Interops with rr-crud via Schema#column_hashes.
module RailsRuntimes
  module Model
    module_function

    def version = VERSION

    def hello
      { ok: true, gem: "rr-model", version: VERSION }
    end

    def define(name, **options, &block)
      Definition.define(name, **options, &block).finalize
    end
  end
end
