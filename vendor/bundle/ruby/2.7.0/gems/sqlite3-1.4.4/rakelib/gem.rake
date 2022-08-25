begin
  require 'hoe'
rescue LoadError
  # try with rubygems?
  require 'rubygems'
  require 'hoe'
end

Hoe.plugin :debugging, :doofus, :git, :minitest, :bundler, :gemspec

HOE = Hoe.spec 'sqlite3' do
  developer           'Jamis Buck', 'jamis@37signals.com'
  developer           'Luis Lavena', 'luislavena@gmail.com'
  developer           'Aaron Patterson', 'aaron@tenderlovemaking.com'

  license             "BSD-3-Clause"

  self.readme_file   = 'README.rdoc'
  self.history_file  = 'CHANGELOG.rdoc'
  self.extra_rdoc_files  = FileList['*.rdoc', 'ext/**/*.c']

  require_ruby_version ">= 1.8.7"
  require_rubygems_version ">= 1.3.5"

  spec_extras[:extensions] = ["ext/sqlite3/extconf.rb"]
  spec_extras[:metadata] = {'msys2_mingw_dependencies' => 'sqlite3'}

  extra_dev_deps << ['rake-compiler', "~> 1.0"]
  extra_dev_deps << ['rake-compiler-dock', "~> 0.6.0"]
  extra_dev_deps << ["mini_portile2", "~> 2.0"]
  extra_dev_deps << ["minitest", "~> 5.0"]
  extra_dev_deps << ["hoe-bundler", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec", "~> 1.0"]

  clean_globs.push('**/test.db')
end

Hoe.add_include_dirs '.'

# vim: syntax=ruby
