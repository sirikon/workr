require "./configuration/config"
require "./web/server"

module Workr

  command = ARGV.size >= 1 ? ARGV[0] : "help"

  case command
  when "help"
    puts "Usage: workr [command]"
    puts ""
    puts "Commands:"
    puts "  configure - Configuration wizard"
    puts "  daemon    - Starts Workr web server"
  when "configure"
    Configuration.wizard
  when "daemon"
    Web::Server.run
  else
    print "Unknown command '#{command}'\n"
  end

end
