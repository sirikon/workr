require "json"
require "./job_info_service.cr"

module Workr::Services::JobDataService
  extend self

  def create_execution(job_name)
    job_info = JobInfoService.get_job(job_name)
    ensure_job_data_folder(job_info.name)

    job_data = read_job_data(job_info.name)
    job_data.increase_execution_id
    write_job_data(job_info.name, job_data)

    return job_data.@last_execution_id
  end

  def ensure_job_data_folder(job_name)
    job_data_folder = get_job_data_folder(job_name)
    if Dir.exists?(job_data_folder)
      return
    end

    Dir.mkdir_p(job_data_folder)
    write_job_data(job_name, JobData.new(0))
  end

  private def get_job_data_folder(job_name)
    return get_data_folder / job_name
  end

  private def get_data_folder
    return Path[Dir.current] / "data"
  end

  private def write_job_data(job_name, job_data)
    File.write(get_job_data_folder(job_name) / "data.json", job_data.to_json)
  end

  private def read_job_data(job_name)
    JobData.from_json(File.read(get_job_data_folder(job_name) / "data.json"))
  end

  private class JobData
    include JSON::Serializable

    def initialize(@last_execution_id : Int32); end

    def increase_execution_id
      @last_execution_id = @last_execution_id + 1
    end
  end

end
