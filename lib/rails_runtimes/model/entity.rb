# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "definition"

module RailsRuntimes
  module Model
    # Thin ergonomic wrapper — not an ORM superclass.
    class Entity
      class << self
        attr_reader :schema_outcome

        def define_schema(name = self.name, **options, &block)
          @schema_outcome = Definition.define(name, **options, &block).finalize
          self
        end

        def schema
          return @schema_outcome.value if @schema_outcome&.ok?

          nil
        end

        def schema!
          s = schema
          raise ArgumentError, "schema invalid" unless s

          s
        end
      end
    end
  end
end
