# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reverse_xslt/version'

Gem::Specification.new do |spec|
  spec.name = 'reverse_xslt'
  spec.version = ReverseXSLT::VERSION
  spec.authors = ['Paweł Kubiak']
  spec.email = ['pawel.kubiak@mnslab.pl']

  spec.summary = 'Reverse XSLT transformation'
  spec.description = %(
    This gem create parser based on xslt file to parse transformed files
  ).strip
  spec.homepage = 'https://github.com/MNSLab/reverse_xslt'
  spec.license = 'MIT'

  unless spec.respond_to?(:metadata)
    raise 'RubyGems 2.0+ is required to protect against public gem pushes.'
  end
  spec.metadata['allowed_push_host'] = 'TODO: Set to "http://mygemserver.com"'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-remote'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
end
