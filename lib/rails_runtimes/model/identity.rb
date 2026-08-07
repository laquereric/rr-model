# frozen_string_literal: true
# Copyright 2026 CBI BUSINESS TRANSACTIONS, LLC
# SPDX-License-Identifier: LicenseRef-DataYoursSoftwareMine-1.0
# Part of RailsRuntimes -- https://github.com/laquereric/DataYoursSoftwareMine

require "securerandom"

module RailsRuntimes
  module Model
    # Client-mintable opaque identifiers (default strategy for portable models).
    module IdentityMint
      module_function

      def mint
        SecureRandom.uuid
      end
    end

    IdentitySpec = Struct.new(:field, :strategy, :external, keyword_init: true) do
      def to_h
        { field: field, strategy: strategy, external: external }
      end
    end
  end
end
