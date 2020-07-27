# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "zfs/snap/version"

Gem::Specification.new do |spec|
  spec.name          = "zfs-snap"
  spec.version       = Zfs::Snap::VERSION
  spec.authors       = ["Andrew L. Moore"]
  spec.email         = ["slewsys@gmail.com"]

  spec.summary       = %q{Library for managing ZFS snapshots.}
  spec.description   = %q{Library for managing ZFS snapshots. It includes a command-line utility, znap, for creating snapshots and destroying expired snapshots.}
  spec.homepage      = "https://github.com/slewsys/zfs-snap"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec-expectations", "~> 3.9"
  spec.add_development_dependency "rspec", "~> 3.9"
end
