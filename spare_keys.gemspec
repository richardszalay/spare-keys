Gem::Specification.new do |s|
  s.name        = 'spare_keys'
  s.version     = '1.1.1'
  s.date        = '2016-10-18'
  s.summary     = "Temporarily keychain switcher"
  s.description = "Isolates keychain access for use with keychain-dependent utilities"
  s.authors     = ["Richard Szalay"]
  s.email       = 'richard@richardszalay.com'
  s.files       = ["lib/spare_keys.rb"]
  s.homepage    =
    'https://github.com/richardszalay/spare-keys'
  s.license       = 'MIT'

  s.add_development_dependency "rspec", "~> 3.2"
  s.add_development_dependency "rake", "~> 0.9.6"
  s.add_development_dependency "bundler", "~> 1.12", ">= 1.12.5"
end
