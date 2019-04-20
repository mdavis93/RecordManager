Gem::Specification.new do |s|
  s.name          = 'record_manager'
  s.version       = '0.0.0'
  s.date          = '2019-02-18'
  s.summary       = 'RecordManager ORM'
  s.description   = 'An ActiveRecord-esque ORM adaptor'
  s.authors       = ['Michael Davis']
  s.email         = 'mdavis93@gmail.com'
  s.files         = Dir['lib/**/*.rb']
  s.require_paths = ["lib"]
  s.homepage      =
      'http://rubygems.org/gems/record_manager'
  s.license       = 'MIT'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'pg', '~> 1.0.0'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
end