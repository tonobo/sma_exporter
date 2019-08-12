# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sma_exporter/version'

Gem::Specification.new do |spec|
  spec.name          = "sma_exporter"
  spec.version       = SmaExporter::VERSION
  spec.authors       = ["Tim Foerster"]
  spec.email         = ["github@mailserver.1n3t.de"]

  spec.summary       = %q{Prometheus exporter for sma data.}
  spec.homepage      = "https://github.com/dopykuh/sma_exporter"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_dependency "prometheus-client"
  spec.add_dependency "rack"
  spec.add_dependency "unicorn"
end
