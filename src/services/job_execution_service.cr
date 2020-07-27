require "./job_info_service"

module Workr::Services::JobExecutionService
  extend self

  def run(job_name)
    job_info = JobInfoService.get_job(job_name)

    process = Process.new(
      command: job_info.entrypoint,
      input: STDIN,
      output: STDOUT,
      error: STDERR,
      chdir: job_info.path)

    process.wait
  end
end
