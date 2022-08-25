## open4.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "open4"
  spec.version = "1.3.4"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "open4"
  spec.description = "open child process with handles on pid, stdin, stdout, and stderr: manage child processes and their io handles easily."
  spec.license = "Ruby"

  spec.files =
["LICENSE",
 "README",
 "README.erb",
 "lib",
 "lib/open4.rb",
 "open4.gemspec",
 "rakefile",
 "samples",
 "samples/bg.rb",
 "samples/block.rb",
 "samples/exception.rb",
 "samples/jesse-caldwell.rb",
 "samples/pfork4.rb",
 "samples/simple.rb",
 "samples/spawn.rb",
 "samples/stdin_timeout.rb",
 "samples/timeout.rb",
 "test",
 "test/lib",
 "test/lib/test_case.rb",
 "test/pfork4_test.rb",
 "test/popen4_test.rb",
 "test/popen4ext_test.rb",
 "white_box",
 "white_box/leak.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/open4"
end
