# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "types"
require_relative "schema"
require_relative "outcome"

module RailsRuntimes
  module Model
    class Definition
      UNSET = Object.new.freeze

      def self.define(name, namespace: nil, table: nil, &block)
        builder = new(name, namespace: namespace, table: table)
        builder.instance_eval(&block) if block
        builder
      rescue StandardError => e
        new(name, namespace: namespace, table: table, initial_error: e.message)
      end

      def initialize(name, namespace:, table:, initial_error: nil)
        @name = name.to_s
        @namespace = (namespace || infer_namespace(name)).to_s
        @table = (table || infer_table(name)).to_s
        @fields = []
        @associations = []
        @validations = []
        @identity = nil
        @sync_policy = SyncPolicy.new(mode: :local_only, scope: nil, conflict: :manual, tombstones: true)
        @errors = []
        @errors << { reason: :invalid_definition, because: initial_error } if initial_error
      end

      def field(name, type:, null: true, default: UNSET, primary_key: false, indexed: false, **metadata)
        if @fields.any? { |f| f.name == name.to_sym }
          @errors << { reason: :duplicate_field, details: { field: name } }
          return self
        end
        unless Types.known?(type)
          @errors << { reason: :unknown_type, details: { field: name, type: type } }
          return self
        end
        if default.respond_to?(:call)
          @errors << { reason: :nonportable_default, details: { field: name } }
          return self
        end
        @fields << Field.new(
          name: name, type: type, null: null, default: default == UNSET ? nil : default,
          primary_key: primary_key, indexed: indexed, metadata: metadata
        )
        self
      end

      def identity(field, strategy: :client_uuid, external: true)
        @identity = IdentitySpec.new(field: field.to_sym, strategy: strategy.to_sym, external: !!external)
        self
      end

      def belongs_to(name, model:, foreign_key: nil, null: true, dependent: :restrict)
        @associations << Association.new(
          name: name.to_sym, kind: :belongs_to, target: model.to_s,
          foreign_key: (foreign_key || "#{name}_id").to_sym, null: !!null, dependent: dependent.to_sym
        )
        self
      end

      def has_many(name, model:, foreign_key:, dependent: :restrict)
        @associations << Association.new(
          name: name.to_sym, kind: :has_many, target: model.to_s,
          foreign_key: foreign_key.to_sym, null: true, dependent: dependent.to_sym
        )
        self
      end

      def validates(field, kind, **options)
        @validations << Validation.new(kind: kind.to_sym, field: field.to_sym, options: options.freeze)
        self
      end

      def sync(scope:, conflict: :manual, tombstones: true)
        @sync_policy = SyncPolicy.new(
          mode: :projection, scope: scope.to_sym, conflict: conflict.to_sym, tombstones: !!tombstones
        )
        self
      end

      def local_only
        @sync_policy = SyncPolicy.new(mode: :local_only, scope: nil, conflict: :manual, tombstones: true)
        self
      end

      def finalize
        validate_identity
        validate_associations
        schema = Schema.new(
          name: @name, namespace: @namespace, table: @table, columns: @fields,
          associations: @associations, validations: @validations, identity: identity_or_placeholder,
          sync_policy: @sync_policy, definition_errors: @errors
        )
        schema.valid_definition? ? Outcome.ok(schema) : Outcome.err(:invalid_schema, details: { errors: @errors, schema: schema })
      rescue StandardError => e
        Outcome.err(:invalid_schema, because: e.message)
      end

      private

      def validate_identity
        if @identity.nil?
          @errors << { reason: :missing_identity }
          return
        end
        field = @fields.find { |c| c.name == @identity.field }
        @errors << { reason: :unknown_identity_field, details: { field: @identity.field } } unless field
        @errors << { reason: :nullable_identity, details: { field: @identity.field } } if field && field.null
        @errors << { reason: :identity_not_primary_key, details: { field: @identity.field } } if field && !field.primary_key
        if @sync_policy.enabled? && @identity.strategy != :client_uuid
          @errors << { reason: :sync_requires_client_minted_identity, details: { strategy: @identity.strategy } }
        end
      end

      def validate_associations
        @associations.select { |a| a.kind == :belongs_to }.each do |association|
          unless @fields.any? { |f| f.name == association.foreign_key }
            @errors << { reason: :missing_foreign_key, details: association.to_h }
          end
        end
      end

      def identity_or_placeholder
        @identity || IdentitySpec.new(field: :id, strategy: :invalid, external: false)
      end

      def infer_namespace(name)
        name.to_s.split("::").first.downcase
      end

      def infer_table(name)
        name.to_s.split("::").last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.concat("s")
      end
    end
  end
end
