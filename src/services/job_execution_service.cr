require "./job_info_service"
require "./job_data_service"

module Workr::Services::JobExecutionService
  extend self

  def run(job_name)
    job_info = JobInfoService.get_job(job_name)
    job_execution_id = JobDataService.create_execution(job_info.name)
    puts "Running job #{job_info.name}##{job_execution_id}"

    process = Process.new(
      command: job_info.entrypoint,
      input: STDIN,
      output: STDOUT,
      error: STDERR,
      chdir: job_info.path)

    process.wait
  end
end
