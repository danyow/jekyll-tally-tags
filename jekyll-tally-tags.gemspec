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

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.add_dependency "jekyll", ">= 3.6", "< 5.0"

  spec.add_development_dependency "bundler"
end
