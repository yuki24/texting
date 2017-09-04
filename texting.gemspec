# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "texting/version"

Gem::Specification.new do |spec|
  spec.name          = "texting"
  spec.version       = Texting::VERSION
  spec.authors       = ["Yuki Nishijima"]
  spec.email         = ["yk.nishijima@gmail.com"]
  spec.summary       = %q{SMS/MMS framework that does not hurt. finally.}
  spec.description   = %q{Texting is like ActionMailer, but for sending SMS/MMS.}
  spec.homepage      = "https://github.com/yuki24/texting"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 4.0.0"
  spec.add_dependency "activejob", ">= 4.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "webmock"
end
