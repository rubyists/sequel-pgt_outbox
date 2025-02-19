# frozen_string_literal: true

require_relative 'lib/sequel/pgt_outbox/version'

Gem::Specification.new do |spec|
  spec.name = 'sequel-pgt_outbox'
  spec.version = Rubyists::PgtOutbox::VERSION
  spec.authors = ['bougyman']
  spec.email = ['bougyman@users.noreply.github.com']

  spec.summary = 'Triggers to implement (an important) part of a transactional outbox pattern.'
  spec.description = 'This implements a configurable outbox and triggers to populate it with events. See https://microservices.io/patterns/data/transactional-outbox.html for details. To be this clear, this only handles the insert of events into the outbox' # rubocop:disable Layout/LineLength
  spec.homepage = 'https://github.com/rubyists/sequel-pgt_outbox'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'sequel_postgresql_triggers', '~> 1.6'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
