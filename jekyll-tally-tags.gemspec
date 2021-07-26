# frozen_string_literal: true

require_relative "lib/jekyll-tally-tags/version"

Gem::Specification.new do |spec|
  spec.name    = "jekyll-tally-tags"
  spec.version = Jekyll::TallyTags::VERSION
  spec.authors = ["Danyow"]
  spec.email   = ["i.zuucol@gmail.com"]

  spec.summary               = "一个基于 *Tags* 的计数插件."
  spec.description           = "开箱即用!"
  spec.homepage              = "https://github.com/danyow/jekyll-tally-tags"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'https://mygemserver.com'"

  all_files  = `git ls-files -z`.split("\x0")
  spec.files = all_files.grep(%r!^(lib)/!)

  spec.add_dependency "jekyll", ">= 3.6", "< 5.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "rubocop-jekyll", "~> 0.9"
  spec.add_development_dependency "shoulda"
end
