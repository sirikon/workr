require "json"
require "./job_info_service.cr"
require "../models/models"

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

  def write_execution_output(job_name, job_execution_id)
    ensure_job_execution_data_folder(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    File.open job_execution_data_folder / "output.log", mode: "a" do |file|
      writing = true
      spawn do
        while writing
          file.fsync
          sleep 2
        end
      end
      yield ->(data: Bytes){
        file.write(data)
      }
      writing = false
    end
  end

  def get_all_executions(job_name)
    job_data_folder = get_job_data_folder(job_name)
    if !Dir.exists?(job_data_folder)
      return [] of Models::JobExecutionData
    end
    Dir.children(get_job_data_folder(job_name))
      .reject! { |id| !Dir.exists?(job_data_folder / id) }
      .map { |id| UInt32.new(id) }
      .sort.reverse
      .map { |id| Models::JobExecutionData.new(id) }
  end

  def get_execution_output(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    File.read(job_execution_data_folder / "output.log")
  end

  private def ensure_job_execution_data_folder(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    if Dir.exists?(job_execution_data_folder)
      return
    end
    Dir.mkdir_p(job_execution_data_folder)
    File.touch(job_execution_data_folder / "output.log")
  end

  private def ensure_job_data_folder(job_name)
    job_data_folder = get_job_data_folder(job_name)
    if Dir.exists?(job_data_folder)
      return
    end

    Dir.mkdir_p(job_data_folder)
    write_job_data(job_name, JobData.new(0))
  end

  private def get_job_execution_data_folder(job_name, job_execution_id)
    get_job_data_folder(job_name) / job_execution_id.to_s
  end

  private def get_job_data_folder(job_name)
    get_data_folder / job_name
  end

  private def get_data_folder
    Path[Dir.current] / "data"
  end

  private def write_job_data(job_name, job_data)
    File.write(get_job_data_folder(job_name) / "data.json", job_data.to_json)
  end

  private def read_job_data(job_name)
    JobData.from_json(File.read(get_job_data_folder(job_name) / "data.json"))
  end

  private class JobData
    include JSON::Serializable

    def initialize(@last_execution_id : UInt32); end

    def increase_execution_id
      @last_execution_id = @last_execution_id + 1
    end
  end

end
