require "router"
require "ecr"
require "../services/job_info_service"
require "../services/job_data_service"
require "../services/job_execution_service"
require "./templates"

module Workr::Web::Server
  extend self

  class WebServer
    include Router

    def draw_routes
      get "/" do |context, params|
        jobs = Services::JobInfoService.get_all_jobs
        context.response.print Templates.run.home(jobs)
        context
      end
      get "/job/:name" do |context, params|
        job_info = Services::JobInfoService.get_job params["name"]
        job_executions = Services::JobDataService.get_all_executions(job_info.name)
        context.response.print Templates.run.job(job_info, job_executions)
        context
      end
      get "/job/:name/execution/:execution" do |context, params|
        job_name = params["name"]
        job_execution_id = UInt32.new(params["execution"])
        job_info = Services::JobInfoService.get_job params["name"]
        job_execution = Services::JobDataService.get_execution job_name, job_execution_id
        job_execution_output = Services::JobDataService.get_execution_output job_name, job_execution_id
        context.response.print Templates.run.job_execution(job_info, job_execution, job_execution_output)
        context
      end
      post "/job/:name/run" do |context, params|
        job_name = params["name"]
        execution_id = Services::JobExecutionService.run(job_name)
        context.response.status = HTTP::Status::SEE_OTHER
        context.response.headers.add("Location", "/job/#{job_name}/execution/#{execution_id}")
        context
      end

      get "/api/job/:name/execution/:execution/output_stream" do |context, params|
        job_name = params["name"]
        job_execution_id = UInt32.new(params["execution"])
        context.response.headers.add("Content-Type", "text/plain")

        job_execution = Services::JobDataService.get_execution job_name, job_execution_id
        if job_execution.finished
          context.response.print Services::JobDataService.get_execution_output job_name, job_execution_id
          next context
        end

        done = Channel(Nil).new
        canceller = Services::JobDataService.subscribe_execution_output job_name, job_execution_id do |bytes|
          if (context.response.closed? || bytes.size == 0)
            done.send(nil)
            next
          end

          if !context.response.closed?
            # Even after checking that the response is closed, it could raise
            # an exception, so it needs handling
            begin
              context.response.write(bytes)
              context.response.flush
            rescue
              done.send(nil)
            end
          else
            done.send(nil)
          end
        end

        done.receive
        canceller.call()
        context
      end
    end

    def run
      server = HTTP::Server.new(route_handler)
      server.bind_tcp 8080
      puts "Listening http://127.0.0.1:8080"
      server.listen
    end
  end

  def run
    web_server = WebServer.new
    web_server.draw_routes
    web_server.run
  end

end
