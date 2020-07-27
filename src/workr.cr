require "./services/job_execution_service"
require "./web/server"

module Workr
  #Services::JobExecutionService.run_wait "pinger"
  Web::Server.run
end
