require 'open4'

echo = lambda do
  $stdout.write $stdin.read
  raise 'finish implementing me'
end

org_message = "hello, world!"
got_message = nil
exception   = nil

begin
  Open4.pfork4(echo) do |cid, stdin, stdout, stderr|
    stdin.write org_message
    stdin.close
    got_message = stdout.read
  end
rescue RuntimeError => e
  exception = e.to_s
end

puts "org_message: #{org_message}"
puts "got_message: #{got_message}"
puts "exception  : #{exception}"
