# frozen_string_literal: true
require_relative 'lib/property_dossier/version'
Gem::Specification.new do |s|
  s.name = 'property_dossier'
  s.version = PropertyDossier::VERSION
  s.summary = 'Inspect property document packs for completeness, conflicting revisions and file integrity.'
  s.description = 'Offline, dependency-free Ruby library and CLI. Explicit manifest requirements, revision chains, expiry checks, SHA-256 verification and escaped HTML/JSON reports. Does not authenticate documents or determine legal title.'
  s.authors = ['NovAsia Estate']
  s.email = ['info@novasia.estate']
  s.homepage = 'https://novasia.estate/'
  s.license = 'MIT'
  s.required_ruby_version = '>= 3.1'
  s.files = Dir['lib/**/*.rb', 'exe/*', 'docs/**/*', 'examples/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md']
  s.bindir = 'exe'
  s.executables = ['property-dossier']
  s.require_paths = ['lib']
  s.metadata = {
    'homepage_uri' => s.homepage,
    'source_code_uri' => 'https://github.com/novasia-estate/property-dossier',
    'bug_tracker_uri' => 'https://github.com/novasia-estate/property-dossier/issues',
    'documentation_uri' => 'https://github.com/novasia-estate/property-dossier/blob/main/docs/manifest.md',
    'changelog_uri' => 'https://github.com/novasia-estate/property-dossier/blob/main/CHANGELOG.md'
  }
end
