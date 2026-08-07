# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

module RailsRuntimes
  module Model
    # One logical model may bind to multiple stores (surfaces).
    # Provenance-only: no triple index — Binding carries routing + IRIs.
    class Binding
      attr_reader :logical_model, :surface, :table, :driver_kind, :iri

      def initialize(logical_model:, surface:, table:, driver_kind: nil, iri: nil)
        @logical_model = logical_model.to_s.freeze
        @surface = surface.to_sym
        @table = table.to_s.freeze
        @driver_kind = driver_kind&.to_sym
        @iri = (iri || default_iri).to_s.freeze
        freeze
      end

      def to_h
        {
          logical_model: logical_model,
          surface: surface,
          table: table,
          driver_kind: driver_kind,
          iri: iri
        }
      end

      def default_iri
        GraphTerms.binding_iri(logical_model: logical_model, surface: surface)
      end
    end

    # Plain urn:rr: IRI helpers (same convention rr-acia emits). No RDF library.
    module GraphTerms
      module_function

      def model_slug(logical_model)
        name = logical_model.to_s
        parts = name.split("::")
        ns = parts.length > 1 ? parts.first.downcase : parts.first.downcase
        model = parts.last.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
        "#{ns}.#{model}"
      end

      def model_iri(logical_model)
        "urn:rr:model:#{model_slug(logical_model)}"
      end

      def binding_iri(logical_model:, surface:)
        "urn:rr:binding:#{model_slug(logical_model)}:#{surface}"
      end

      def record_iri(entity_token)
        "urn:rr:record:#{entity_token}"
      end

      def store_iri(surface, driver_kind)
        "urn:rr:store:#{surface}:#{driver_kind}"
      end

      def surface_iri(surface)
        "urn:rr:surface:#{surface}"
      end

      # Class-level terms for a schema's bindings.
      def for_schema(schema)
        terms = []
        model = model_iri(schema.name)
        Array(schema.bindings).each do |binding|
          terms << [model, "urn:rr:hasBinding", binding.iri]
          terms << [binding.iri, "urn:rr:onSurface", surface_iri(binding.surface)]
          terms << [binding.iri, "urn:rr:table", binding.table]
          if binding.driver_kind
            terms << [binding.iri, "urn:rr:driverKind", binding.driver_kind.to_s]
          end
        end
        terms.map { |t| t.map(&:freeze).freeze }.freeze
      end

      # Instance terms for a record origin.
      def for_origin(origin)
        return [].freeze if origin.nil?

        rec = record_iri(origin.entity_token)
        [
          [rec, "urn:rr:logicalModel", origin.logical_model],
          [rec, "urn:rr:storedIn", store_iri(origin.surface, origin.driver_kind)],
          [rec, "urn:rr:onSurface", surface_iri(origin.surface)],
          [rec, "urn:rr:inTable", origin.table],
          [rec, "urn:rr:viaBinding", origin.binding_iri]
        ].map { |t| t.map(&:freeze).freeze }.freeze
      end
    end
  end
end
