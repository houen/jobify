# frozen_string_literal: true

require_relative "lib/jobify/version"

Gem::Specification.new do |spec|
  spec.name = "jobify"
  spec.version = Jobify::VERSION
  spec.authors = ["Søren Houen"]
  spec.email = ["s@houen.net"]

  spec.summary = "Turn any method into a background job (`jobify :hello_world` generates `def perform_hello_world_later`"
  spec.homepage = "https://github.com/houen/jobify"

  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/houen/jobify"
  spec.metadata["changelog_uri"] = "https://github.com/houen/jobify/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activejob"
  spec.add_dependency "activesupport"
  
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rubocop", "~> 1.21"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
