# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require "spec_helper"

RSpec.describe RailsRuntimes::Model do
  it "has a version and hello envelope" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+/)
    expect(described_class.hello[:ok]).to be(true)
  end

  it "defines a model and compiles a schema descriptor" do
    out = described_class.define("Notes::Note", table: "rr_notes_notes") do
      field :id, type: :uuid, null: false, primary_key: true, default: "__rr_uuid__"
      field :title, type: :string, null: false, default: ""
      field :body, type: :text, null: true
      identity :id, strategy: :client_uuid
      validates :title, :presence
      validates :title, :length, maximum: 200
      local_only
    end
    expect(out.ok?).to be(true), out.to_h.inspect
    schema = out.value
    expect(schema.table).to eq("rr_notes_notes")
    expect(schema.columns.map(&:name)).to include(:id, :title, :body)
    expect(schema.column(:title).null).to be(false)
    expect(schema.fingerprint).to match(/\A[a-f0-9]{64}\z/)
  end

  it "exposes column hashes consumable by rr-crud.derive_columns" do
    out = described_class.define("Widgets::Widget") do
      field :id, type: :uuid, null: false, primary_key: true
      field :name, type: :string, null: false
      field :qty, type: :integer, null: true
      field :active, type: :boolean, null: true
      identity :id
    end
    schema = out.value
    cols = schema.column_hashes
    expect(cols).to all(include(:name, :type, :null).or(include("name", "type", "null")).or(satisfy { |c| c.key?(:name) || c.key?("name") }))
    # symbol keys
    by = cols.each_with_object({}) { |c, h| h[c[:name].to_s] = c }
    expect(by["name"][:type]).to eq(:string)
    expect(by["name"][:null]).to be(false)
    expect(by["qty"][:type]).to eq(:integer)

    # CRITICAL acceptance: feed rr-crud unchanged
    begin
      require "rails_runtimes/crud"
    rescue LoadError
      skip "rr-crud not available"
    end
    crud = RailsRuntimes::Crud.derive_columns(name: "Widget", columns: schema.column_hashes)
    expect(crud[:ok]).to be(true), crud.inspect
    expect(crud[:create]["kind"]).to eq("form")
    fields = crud[:create]["children"].select { |c| c["kind"] == "field" }
    by_input = fields.each_with_object({}) { |f, h| h[f["name"]] = f["input_type"] }
    expect(by_input["name"]).to eq("text")
    expect(by_input["qty"]).to eq("number")
    expect(by_input["active"]).to eq("checkbox")
  end

  it "validates presence" do
    out = described_class.define("T") do
      field :id, type: :uuid, null: false, primary_key: true
      field :title, type: :string, null: false
      identity :id
      validates :title, :presence
    end
    schema = out.value
    bad = RailsRuntimes::Model::Validator.validate(schema, { id: "x", title: "" })
    expect(bad.err?).to be(true)
    expect(bad.reason).to eq(:invalid)
    good = RailsRuntimes::Model::Validator.validate(schema, { id: "x", title: "Hi" })
    expect(good.ok?).to be(true)
  end

  it "mints client UUIDs" do
    id = RailsRuntimes::Model::IdentityMint.mint
    expect(id).to match(/\A[0-9a-f-]{36}\z/i)
  end

  it "supports multi-store bindings and class-level graph_terms" do
    out = described_class.define("Notes::Note", table: "notes") do
      field :id, type: :uuid, null: false, primary_key: true
      field :title, type: :string, null: false
      identity :id
      store surface: :server, table: "notes", driver_kind: :active_record
      store surface: :browser, table: "notes", driver_kind: :opfs_sqlite
      local_only
    end
    expect(out.ok?).to be(true), out.to_h.inspect
    schema = out.value
    expect(schema.name).to eq("Notes::Note")
    expect(schema.bindings.map(&:surface)).to contain_exactly(:server, :browser)
    expect(schema.binding_for(:server).driver_kind).to eq(:active_record)
    expect(schema.binding_for(:browser).table).to eq("notes")
    expect(schema.binding_for(:server).iri).to eq("urn:rr:binding:notes.note:server")

    terms = schema.graph_terms
    expect(terms).to be_frozen
    expect(terms).to include(
      ["urn:rr:model:notes.note", "urn:rr:hasBinding", "urn:rr:binding:notes.note:server"]
    )
    expect(terms).to include(
      ["urn:rr:model:notes.note", "urn:rr:hasBinding", "urn:rr:binding:notes.note:browser"]
    )
    expect(terms).to include(
      ["urn:rr:binding:notes.note:server", "urn:rr:driverKind", "active_record"]
    )
    expect(terms).to include(
      ["urn:rr:binding:notes.note:browser", "urn:rr:driverKind", "opfs_sqlite"]
    )
  end

  it "derives a default binding when store is omitted (0.1.0 back-compat)" do
    out = described_class.define("Solo::Item", table: "items") do
      field :id, type: :uuid, null: false, primary_key: true
      identity :id
    end
    schema = out.value
    expect(schema.bindings.size).to eq(1)
    expect(schema.binding_for(:default).table).to eq("items")
  end

  it "contains no private-substrate vocabulary in library sources" do
    root = File.expand_path("../lib", __dir__)
    hits = Dir[File.join(root, "**", "*.rb")].flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, i|
        if line.match?(/\b(Mmg|mmg-|urn:mm:|epic_|SAL|substrate|vv-|a2a)\b/i)
          "#{path}:#{i + 1}:#{line.strip}"
        end
      end
    end
    expect(hits).to eq([])
  end
end
