require "./job_info_service"
require "./job_data_service"

module Workr::Services::JobExecutionService
  extend self

  def run(job_name)
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

    spawn do
      JobDataService.open_execution_output job_info.@name, job_execution_id do |file|
        writing = true

        spawn do
          output_reader.each_byte do |byte|
            bytes = Slice.new(1, byte)
            file.write(bytes)
            print String.new(bytes)
          end
        end

        spawn do
          while writing
            file.fsync
            sleep 2
          end
        end

        process_finished.receive
        writing = false
      end
      output_finished.send(nil)
    end

    process.wait
    process_finished.send(nil)
    output_finished.receive
  end
end
