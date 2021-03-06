# frozen_string_literal: true

require "readall"
require "cli/parser"

module Homebrew
  module_function

  def readall_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `readall` [<options>] [<tap>]

        Import all formulae from the specified <tap>, or from all installed taps if none is provided.
        This can be useful for debugging issues across all formulae when making
        significant changes to `formula.rb`, testing the performance of loading
        all formulae or checking if any current formulae have Ruby issues.
      EOS
      switch "--aliases",
             description: "Verify any alias symlinks in each tap."
      switch "--syntax",
             description: "Syntax-check all of Homebrew's Ruby files."
      switch :verbose
      switch :debug
    end
  end

  def readall
    readall_args.parse

    if args.syntax?
      scan_files = "#{HOMEBREW_LIBRARY_PATH}/**/*.rb"
      ruby_files = Dir.glob(scan_files).reject { |file| file =~ %r{/(vendor|cask)/} }

      Homebrew.failed = true unless Readall.valid_ruby_syntax?(ruby_files)
    end

    options = { aliases: args.aliases? }
    taps = if args.no_named?
      Tap
    else
      args.named.map { |t| Tap.fetch(t) }
    end
    taps.each do |tap|
      Homebrew.failed = true unless Readall.valid_tap?(tap, options)
    end
  end
end
