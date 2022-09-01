# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zfs/snap/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.1.2'
  spec.name          = 'zfs-snap'
  spec.version       = ZFS::Snap::VERSION
  spec.authors       = ['Andrew L. Moore']
  spec.email         = ['slewsys@gmail.com']

  spec.summary       = %w[Library for managing ZFS snapshots.]
  spec.description   = <<-DESC
    Library for managing ZFS snapshots. It includes a command-line
    utility, znap, for creating snapshots and destroying expired
    snapshots.
  DESC
  spec.homepage      = 'https://github.com/slewsys/zfs-snap'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler', '~> 2.3'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'rspec', '~> 3.11'
  spec.add_dependency 'rspec-expectations', '~> 3.11'
  spec.add_development_dependency 'rubocop', '~> 1.34'
  spec.add_development_dependency 'solargraph'
end
