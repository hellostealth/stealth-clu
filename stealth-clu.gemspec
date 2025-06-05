$LOAD_PATH.push File.expand_path('../lib', __FILE__)

version = File.read(File.join(File.dirname(__FILE__), 'VERSION')).strip

Gem::Specification.new do |s|
  s.name        = 'stealth-clu'
  s.version     = version
  s.summary     = "Stealth CLU"
  s.description = "Built-in NLP for Stealth bots via Microsoft's Conversational Language Understanding (CLU)"
  s.authors     = ["Emilie Morissette"]
  s.email       = 'emorissettegregoire@gmail.com'
  s.homepage    = 'http://github.com/hellostealth/stealth-clu'
  s.license     = 'MIT'

  s.add_dependency 'stealth', '>= 2.0.0.beta'
  s.add_dependency 'http', '~> 4'

  s.add_development_dependency "rspec", "~> 3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
