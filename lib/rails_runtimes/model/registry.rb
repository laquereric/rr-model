# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: LicenseRef-DataYoursSoftwareMine-1.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "outcome"

module RailsRuntimes
  module Model
    class Registry
      def initialize(schemas = [])
        @schemas = schemas.each_with_object({}) { |schema, index| index[schema.name] = schema }.freeze
      end

      def fetch(name)
        schema = @schemas[name.to_s]
        schema ? Outcome.ok(schema) : Outcome.err(:unknown_model, details: { model: name })
      end

      def names
        @schemas.keys.sort
      end

      def register(schema)
        self.class.new(@schemas.values + [schema])
      end
    end
  end
end
