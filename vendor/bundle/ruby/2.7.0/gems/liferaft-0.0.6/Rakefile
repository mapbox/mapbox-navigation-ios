require 'bundler/gem_tasks'

def specs(dir)
  list = FileList["spec/#{dir}/*_spec.rb"]
  list.sample(list.count).join(' ')
end

desc 'Runs all the specs'
task :spec do
  sh "bundle exec bacon #{specs('**')}"
end

task default: :spec
