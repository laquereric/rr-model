# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: Apache-2.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require_relative "lib/rails_runtimes/model/version"

Gem::Specification.new do |spec|
  spec.name        = "rr-model"
  spec.version     = RailsRuntimes::Model::VERSION
  spec.authors     = ["Eric Laquer"]
  spec.email       = ["LaquerEric@gmail.com"]
  spec.summary     = "Portable pure-Ruby model DSL and schema descriptor for RailsRuntimes; compiles to columns consumable by rr-crud."
  spec.description = spec.summary
  spec.homepage    = "https://github.com/laquereric/DataYoursSoftwareMine"
  spec.license     = "LicenseRef-DataYoursSoftwareMine-1.0"
  spec.required_ruby_version = ">= 3.1"
  spec.files = Dir["lib/**/*", "README.md", "LICENSE", "NOTICE"].select { |f| File.file?(f) }
  spec.require_paths = ["lib"]
  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "https://github.com/laquereric/rr-model",
    "rubygems_mfa_required" => "true"
  }
  spec.add_development_dependency "rspec", "~> 3.0"
  # Interop acceptance: schema columns → rr-crud.derive_columns
  spec.add_development_dependency "rr-crud", ">= 0.1.0"
end
