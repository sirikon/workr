require "./services/job_execution_service"

module Workr
  Services::JobExecutionService.run "pinger"
end
