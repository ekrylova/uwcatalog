lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uw_catalog/version'

Gem::Specification.new do |gem|
  gem.name          = "uw_catalog"
  gem.version       = UwCatalog::VERSION
  gem.authors       = ["Ev Krylova"]
  gem.email         = ["ekrylova@wisc.edu"]
  gem.description   = %q{Gem for the University of Wisconsin Library Voyager catalog data}
  gem.summary       = %q{Use UW-Madison Voyager catalog data}
  gem.homepage      = "https://github.com/ekrylova/uw_catalog"
  
  gem.add_dependency('data_mapper', '~>1.2.0')

  gem.files         = `git ls-files`.split($/)
  gem.files         = [
     # "Gemfile",
     # "Rakefile",
      "uw_catalog.gemspec",
      "lib/uw_catalog.rb",
      "lib/uw_catalog/model/location.rb",
      "lib/uw_catalog/model/holding.rb",
      "lib/uw_catalog/model/bib_data.rb",
      "lib/uw_catalog/model/item.rb",
      "lib/uw_catalog/model/items_listing.rb",
      "lib/uw_catalog/version.rb",
      "lib/uw_catalog/catalog.rb",
      "lib/uw_catalog/data_loader.rb",
      "lib/uw_catalog/voyager_item_status.rb",
      "lib/uw_catalog/voyager_sql.rb"
    ]
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'

  gem.add_dependency('data_mapper', '~> 1.2.0')
  gem.add_dependency('dm-oracle-adapter', '~> 1.2.0')
  gem.add_dependency('ruby-oci8', '~> 2.1.3')

end
