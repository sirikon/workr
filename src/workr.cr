require "./services/job_execution_service"
require "./web/server"

module Workr
  Web::Server.run
end
