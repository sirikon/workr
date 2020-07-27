require "./job_info_service"
require "./job_data_service"

module Workr::Services::JobExecutionService
  extend self

  def run(job_name)
    job_info = JobInfoService.get_job(job_name)
    job_execution_id = JobDataService.create_execution(job_info.name)
    puts "Running job #{job_info.name}##{job_execution_id}"

    outputReader, outputWriter = IO.pipe(write_blocking: true)

    process = Process.new(
      command: job_info.entrypoint,
      output: outputWriter,
      error: outputWriter,
      chdir: job_info.path)

    processFinished = Channel(Nil).new
    outputFinished = Channel(Nil).new

    spawn do
      JobDataService.open_execution_output job_info.@name, job_execution_id do |file|
        writing = true

        spawn do
          outputReader.each_byte do |byte|
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

        processFinished.receive
        writing = false
      end
      outputFinished.send(nil)
    end

    process.wait
    processFinished.send(nil)
    outputFinished.receive
  end
end
