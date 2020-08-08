require "../models/models"

module Workr::Services::JobInfoService
  extend self

  def get_all_jobs
    Dir.children(get_jobs_folder).sort.map do |job_name|
      Models::JobInfo.new(
        job_name,
        get_job_path(job_name).to_s,
        get_job_entrypoint(job_name).to_s)
    end
  end

  def get_job(job_name)
    job_path = get_job_path(job_name)
    if !Dir.exists?(job_path)
      raise "Job with name #{job_name} does not exist"
    end
    Models::JobInfo.new(
      job_name,
      job_path.to_s,
      get_job_entrypoint(job_name).to_s)
  end

  private def get_job_entrypoint(job_name)
    return get_job_path(job_name) / "run"
  end

  private def get_job_path(job_name)
    return get_jobs_folder / job_name
  end

  private def get_jobs_folder
    return Path[Dir.current] / "jobs"
  end
end
