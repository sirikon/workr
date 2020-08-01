require "./configuration/config"
require "./web/server"

module Workr
  VERSION = {{ `shards version`.stringify }}
  command = ARGV.size >= 1 ? ARGV[0] : "help"

  case command
  when "help"
    puts "Usage: workr [command]"
    puts ""
    puts "Commands:"
    puts "  configure - Configuration wizard"
    puts "  daemon    - Starts Workr web server"
    puts "  version   - Displays Workr version"
  when "configure"
    Configuration.wizard
  when "daemon"
    Web::Server.run
  when "version"
    puts VERSION
  else
    print "Unknown command '#{command}'\n"
  end
end
