# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: LicenseRef-DataYoursSoftwareMine-1.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require "digest"
require "json"
require_relative "identity"
require_relative "binding"

module RailsRuntimes
  module Model
    # Field exposes name/type/null for rr-crud.derive_columns interop.
    class Field
      attr_reader :name, :type, :null, :default, :primary_key, :indexed, :metadata

      def initialize(name:, type:, null:, default:, primary_key:, indexed:, metadata: {})
        @name = name.to_sym
        @type = type.to_sym
        @null = !!null
        @default = default
        @primary_key = !!primary_key
        @indexed = !!indexed
        @metadata = (metadata || {}).freeze
        freeze
      end

      def to_h
        {
          name: name, type: type, null: null, default: default,
          primary_key: primary_key, indexed: indexed, metadata: metadata
        }
      end

      def to_column_hash
        { name: name.to_s, type: type, null: null }
      end
    end

    Association = Struct.new(:name, :kind, :target, :foreign_key, :null, :dependent, keyword_init: true) do
      def to_h
        { name: name, kind: kind, target: target, foreign_key: foreign_key, null: null, dependent: dependent }
      end
    end

    Validation = Struct.new(:kind, :field, :options, keyword_init: true) do
      def to_h
        { kind: kind, field: field, options: options }
      end
    end

    SyncPolicy = Struct.new(:mode, :scope, :conflict, :tombstones, keyword_init: true) do
      def to_h
        { mode: mode, scope: scope, conflict: conflict, tombstones: tombstones }
      end

      def enabled?
        mode == :projection
      end
    end

    class Schema
      attr_reader :name, :namespace, :table, :columns, :associations, :validations,
                  :identity, :sync_policy, :bindings, :descriptor_version, :definition_errors

      def initialize(name:, namespace:, table:, columns:, associations:, validations:,
                     identity:, sync_policy:, bindings: [], descriptor_version: 1, definition_errors: [])
        @name = name.to_s.freeze
        @namespace = namespace.to_s.freeze
        @table = table.to_s.freeze
        @columns = columns.freeze
        @associations = associations.freeze
        @validations = validations.freeze
        @identity = identity
        @sync_policy = sync_policy
        @bindings = Array(bindings).freeze
        @descriptor_version = descriptor_version
        @definition_errors = definition_errors.freeze
        freeze
      end

      def valid_definition?
        definition_errors.empty?
      end

      def column(name)
        columns.find { |field| field.name == name.to_sym }
      end

      def primary_key
        column(identity.field)
      end

      def sync_enabled?
        sync_policy.enabled?
      end

      def column_hashes
        columns.map(&:to_column_hash)
      end

      def binding_for(surface)
        surface = surface.to_sym
        bindings.find { |b| b.surface == surface } ||
          bindings.find { |b| b.surface == :default }
      end

      def table_for(surface)
        binding_for(surface)&.table || table
      end

      # Class-level store-origin provenance (plain frozen [s,p,o] arrays).
      def graph_terms
        GraphTerms.for_schema(self)
      end

      def model_iri
        GraphTerms.model_iri(name)
      end

      def descriptor_body
        {
          descriptor_version: descriptor_version,
          name: name,
          namespace: namespace,
          table: table,
          columns: columns.map(&:to_h),
          associations: associations.map(&:to_h),
          validations: validations.map(&:to_h),
          identity: identity.to_h,
          sync: sync_policy.to_h,
          bindings: bindings.map(&:to_h)
        }
      end

      def to_h
        descriptor_body.merge(fingerprint: fingerprint)
      end

      def canonical_json
        JSON.generate(canonicalize(descriptor_body))
      end

      def fingerprint
        Digest::SHA256.hexdigest(canonical_json)
      end

      private

      def canonicalize(value)
        case value
        when Hash
          value.keys.sort_by(&:to_s).to_h { |key| [key.to_s, canonicalize(value[key])] }
        when Array
          value.map { |item| canonicalize(item) }
        when Symbol
          value.to_s
        else
          value
        end
      end
    end
  end
end
