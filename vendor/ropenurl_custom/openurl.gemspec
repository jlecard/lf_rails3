require 'rubygems'
spec = Gem::Specification.new do |s|
    s.name = 'ropenurl'
    s.version = '0.0.2'
    s.author = 'Ross Singer'
    s.email = 'rossfsinger@gmail.com'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with OpenURLs'
    s.files = Dir.glob("{lib,test}/**/*")
    s.require_path = 'lib'
    s.autorequire = 'ropenurl'
    s.has_rdoc = true
    s.test_file = 'test.rb'
end

if $0 == __FILE__
    Gem::manage_gems
    Gem::Builder.new(spec).build
end

