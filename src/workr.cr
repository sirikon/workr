require "./services/job_execution_service"

module Workr
  Services::JobExecutionService.run_wait "pinger"
end
