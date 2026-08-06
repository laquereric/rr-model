# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "types"
require_relative "outcome"
require_relative "identity"

module RailsRuntimes
  module Model
    module Validator
      module_function

      def validate(schema, candidate, existing: nil)
        values = apply_defaults(schema, candidate, existing: existing)
        errors = {}

        schema.columns.each do |field|
          value = values[field.name]
          if value.nil? && !field.null
            add(errors, field.name, :blank)
            next
          end
          next if value.nil?

          normalized = Types.normalize(field.type, value)
          if normalized.err?
            add(errors, field.name, :invalid_type, expected: field.type)
          else
            values[field.name] = normalized.value
          end
        end

        schema.validations.each do |rule|
          value = values[rule.field]
          case rule.kind
          when :presence
            add(errors, rule.field, :blank) if value.nil? || value.to_s.empty?
          when :length
            minimum = rule.options[:minimum]
            maximum = rule.options[:maximum]
            add(errors, rule.field, :too_short, minimum: minimum) if minimum && value.to_s.length < minimum
            add(errors, rule.field, :too_long, maximum: maximum) if maximum && value.to_s.length > maximum
          when :inclusion
            allowed = Array(rule.options[:in])
            add(errors, rule.field, :not_included, allowed: allowed) unless allowed.include?(value)
          when :format
            pattern = rule.options[:pattern].to_s
            add(errors, rule.field, :invalid_format) unless Regexp.new(pattern).match?(value.to_s)
          else
            add(errors, rule.field, :unsupported_validation, kind: rule.kind)
          end
        end

        errors.empty? ? Outcome.ok(values.freeze) : Outcome.err(:invalid, details: { fields: errors, values: values })
      rescue StandardError => e
        Outcome.err(:validation_failed, because: e.message)
      end

      def apply_defaults(schema, candidate, existing:)
        source = (existing ? existing.dup : {}).merge(candidate.transform_keys(&:to_sym))
        schema.columns.each_with_object(source) do |field, values|
          next if values.key?(field.name)

          values[field.name] = default_value(field.default)
        end
      end

      def default_value(default)
        case default
        when "__rr_now__" then Time.now.utc.iso8601
        when "__rr_uuid__" then IdentityMint.mint
        else default
        end
      end

      def add(errors, field, code, **details)
        errors[field] ||= []
        errors[field] << { code: code, details: details }
      end
    end
  end
end
