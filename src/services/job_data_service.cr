require "json"
require "./job_info_service.cr"
require "../models/models"

module Workr::Services::JobDataService
  extend self

  @@job_execution_output_subscribers = {} of String => Array(Bytes -> Nil)
  @@job_execution_output_cache = {} of String => Array(Bytes)

  def create_execution(job_name)
    job_info = JobInfoService.get_job(job_name)

    ensure_job_data_folder(job_info.name)
    job_data = read_job_data(job_info.name).not_nil!
    job_data.increase_execution_id
    write_job_data(job_info.name, job_data)

    ensure_job_execution_data_folder(job_info.name, job_data.@latest_execution_id)
    job_execution_data = read_job_execution_data(job_info.name, job_data.@latest_execution_id).not_nil!
    job_execution_data.set_start_date(Time.utc)
    write_job_execution_data(job_info.name, job_data.@latest_execution_id, job_execution_data)

    return job_data.@latest_execution_id
  end

  def finish_execution(job_name, job_execution_id, exit_code)
    job_execution_data = read_job_execution_data(job_name, job_execution_id).not_nil!
    job_execution_data.set_end_date(Time.utc)
    job_execution_data.set_exit_code(exit_code)
    write_job_execution_data(job_name, job_execution_id, job_execution_data)
  end

  def write_execution_output(job_name : String, job_execution_id : UInt32)
    ensure_job_execution_data_folder(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    File.open job_execution_data_folder / "output.log", mode: "a" do |file|
      writing = true
      spawn do
        while writing
          file.fsync
          empty_output_cache(job_name, job_execution_id)
          sleep 2
        end
      end
      yield ->(data : Bytes) {
        file.write(data)
        send_output_to_subscribers(job_name, job_execution_id, data)
      }
      file.fsync
      send_output_to_subscribers(job_name, job_execution_id, Slice(UInt8).new(0))
      writing = false
    end
  end

  def get_job(job_name)
    job_data = read_job_data(job_name)
    if job_data.nil?
      return nil
    end
    Models::JobData.new(job_name, job_data.not_nil!.@latest_execution_id)
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
      .map { |id| {id: id, data: read_job_execution_data(job_name, id)} }
      .reject! { |job| job["data"].nil? }
      .map { |job|
        Models::JobExecutionData.new(
          job["id"],
          job["data"].not_nil!.@start_date,
          job["data"].not_nil!.@end_date,
          !job["data"].not_nil!.@end_date.nil?,
          job["data"].not_nil!.@exit_code)
      }
  end

  def get_execution(job_name : String, job_execution_id : UInt32)
    job_execution_data = read_job_execution_data(job_name, job_execution_id)
    if job_execution_data.nil?
      return nil
    end
    Models::JobExecutionData.new(
      job_execution_id,
      job_execution_data.not_nil!.@start_date,
      job_execution_data.not_nil!.@end_date,
      !job_execution_data.not_nil!.@end_date.nil?,
      job_execution_data.not_nil!.@exit_code)
  end

  def get_execution_output(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    File.read(job_execution_data_folder / "output.log")
  end

  def subscribe_execution_output(job_name, job_execution_id, &subscriber : Bytes -> Nil)
    job_execution_key = "#{job_name}##{job_execution_id}"

    if !@@job_execution_output_subscribers.has_key?(job_execution_key)
      @@job_execution_output_subscribers[job_execution_key] = [] of Bytes -> Nil
    end
    @@job_execution_output_subscribers[job_execution_key] << subscriber

    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    if File.exists?(job_execution_data_folder / "output.log")
      file = File.open(job_execution_data_folder / "output.log", mode: "r")
      file.each_byte do |byte|
        subscriber.call(Slice(UInt8).new(1, byte))
      end
      file.close
    end

    if @@job_execution_output_cache.has_key?(job_execution_key)
      @@job_execution_output_cache[job_execution_key].each do |bytes|
        subscriber.call(bytes)
      end
    end

    ->{
      @@job_execution_output_subscribers[job_execution_key].delete(subscriber)
      if @@job_execution_output_subscribers[job_execution_key].size == 0
        @@job_execution_output_subscribers.delete(job_execution_key)
      end
    }
  end

  private def send_output_to_subscribers(job_name, job_execution_id, bytes)
    job_execution_key = "#{job_name}##{job_execution_id}"

    if (bytes.size > 0)
      if !@@job_execution_output_cache.has_key?(job_execution_key)
        @@job_execution_output_cache[job_execution_key] = [] of Bytes
      end
      @@job_execution_output_cache[job_execution_key] << bytes
    else
      if @@job_execution_output_cache.has_key?(job_execution_key)
        @@job_execution_output_cache.delete(job_execution_key)
      end
    end

    if !@@job_execution_output_subscribers.has_key?(job_execution_key)
      return
    end
    @@job_execution_output_subscribers[job_execution_key].each do |subscriber|
      subscriber.call(bytes)
    end

    if (bytes.size == 0)
      empty_output_cache(job_name, job_execution_id)
    end
  end

  private def empty_output_cache(job_name, job_execution_id)
    job_execution_key = "#{job_name}##{job_execution_id}"
    if @@job_execution_output_cache.has_key?(job_execution_key)
      @@job_execution_output_cache[job_execution_key].clear
    end
  end

  private def ensure_job_execution_data_folder(job_name, job_execution_id)
    job_execution_data_folder = get_job_execution_data_folder(job_name, job_execution_id)
    if Dir.exists?(job_execution_data_folder)
      return
    end
    Dir.mkdir_p(job_execution_data_folder)
    write_job_execution_data(job_name, job_execution_id, JobExecutionData.new(Time.unix(0), nil, nil))
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
    data_path = get_job_data_folder(job_name) / "data.json"
    if !File.exists?(data_path)
      return nil
    end
    JobData.from_json(File.read(data_path))
  end

  private def write_job_execution_data(job_name, job_execution_id, job_execution_data)
    File.write(get_job_execution_data_folder(job_name, job_execution_id) / "data.json", job_execution_data.to_json)
  end

  private def read_job_execution_data(job_name, job_execution_id)
    data_path = get_job_execution_data_folder(job_name, job_execution_id) / "data.json"
    if !File.exists?(data_path)
      return nil
    end
    JobExecutionData.from_json(File.read(data_path))
  end

  private class JobData
    include JSON::Serializable

    def initialize(
      @latest_execution_id : UInt32
    ); end

    def increase_execution_id
      @latest_execution_id = @latest_execution_id + 1
    end
  end

  private class JobExecutionData
    include JSON::Serializable

    def initialize(
      @start_date : Time,
      @end_date : Time?,
      @exit_code : Int32?
    ); end

    def set_start_date(date)
      @start_date = date
    end

    def set_end_date(date)
      @end_date = date
    end

    def set_exit_code(exit_code)
      @exit_code = exit_code
    end
  end
end
