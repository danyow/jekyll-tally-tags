# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in jekyll-tally-tags.gemspec
gemspec

if ENV["GH_PAGES"]
  gem "github-pages"
elsif ENV["JEKYLL_VERSION"]
  gem "jekyll", ENV["JEKYLL_VERSION"]
end