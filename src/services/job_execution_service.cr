require "./job_info_service"
require "./job_data_service"

module Workr::Services::JobExecutionService
  extend self

  def run(job_name : String, wait : Bool = false)
    execution_id, waiter = run_internal(job_name)
    if wait
      waiter.call()
    else
      spawn do
        waiter.call()
      end
    end
    return execution_id
  end

  private def run_internal(job_name : String)
    job_info = JobInfoService.get_job(job_name)
    job_execution_id = JobDataService.create_execution(job_info.name)
    puts "Running job #{job_info.name}##{job_execution_id}"

    output_reader, output_writer = IO.pipe(write_blocking: true)

    process = Process.new(
      command: job_info.entrypoint,
      output: output_writer,
      error: output_writer,
      chdir: job_info.path)

    process_finished = Channel(Nil).new
    output_finished = Channel(Nil).new
    done = Channel(Nil).new

    spawn do
      JobDataService.write_execution_output job_info.@name, job_execution_id do |writer|
        spawn do
          output_reader.each_byte do |byte|
            bytes = Slice.new(1, byte)
            writer.call(bytes)
            print String.new(bytes)
          end
        end
        process_finished.receive
      end
      output_finished.send(nil)
    end

    spawn do
      process.wait
      process_finished.send(nil)
      output_finished.receive
      done.send(nil)
    end

    return job_execution_id, ->{ done.receive }
  end
end
