# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

module RailsRuntimes
  module Model
    module Types
      ALL = %i[
        string text integer decimal float boolean date datetime json binary uuid
      ].freeze

      SQLITE_AFFINITY = {
        string: "TEXT", text: "TEXT", integer: "INTEGER", decimal: "TEXT",
        float: "REAL", boolean: "INTEGER", date: "TEXT", datetime: "TEXT",
        json: "TEXT", binary: "BLOB", uuid: "TEXT"
      }.freeze

      module_function

      def known?(name)
        ALL.include?(name.to_sym)
      end

      def normalize(name, value)
        return Outcome.ok(nil) if value.nil?

        case name.to_sym
        when :string, :text, :uuid then Outcome.ok(value.to_s)
        when :integer then integer(value)
        when :decimal then Outcome.ok(value.to_s)
        when :float then Outcome.ok(Float(value))
        when :boolean then boolean(value)
        when :date, :datetime then Outcome.ok(value.to_s)
        when :json then Outcome.ok(value)
        when :binary then Outcome.ok(value)
        else Outcome.err(:unknown_type, details: { type: name })
        end
      rescue ArgumentError, TypeError => e
        Outcome.err(:invalid_type, because: e.message, details: { type: name, value: value })
      end

      def integer(value)
        return Outcome.ok(value) if value.is_a?(Integer)
        return Outcome.err(:invalid_type, details: { type: :integer, value: value }) unless value.to_s.match?(/\A-?\d+\z/)

        Outcome.ok(value.to_i)
      end

      def boolean(value)
        return Outcome.ok(value) if value == true || value == false
        return Outcome.ok(true) if value == 1 || value == "1" || value == "true"
        return Outcome.ok(false) if value == 0 || value == "0" || value == "false"

        Outcome.err(:invalid_type, details: { type: :boolean, value: value })
      end
    end
  end
end
