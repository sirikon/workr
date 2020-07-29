require "router"
require "ecr"
require "../services/job_info_service"
require "../services/job_data_service"
require "../services/job_execution_service"
require "./templates"
require "../models/models"

module Workr::Web::Server
  extend self

  class WebServer
    include Router

    macro reply_asset(ctx, path, content_type)
      {{ctx}}.response.headers.add("Cache-Control", "max-age=3600")
      {{ctx}}.response.content_type = {{content_type}}
      {% if flag?(:embed_web_assets) %}
        {{ctx}}.response.print {{ read_file("#{__DIR__}/assets/" + path) }}
      {% else %}
        {{ctx}}.response.print File.read("#{__DIR__}/assets/" + {{path}})
      {% end %}
      {{ctx}}
    end

    def draw_routes
      get "/" do |context, params|
        jobs = Services::JobInfoService.get_all_jobs.map do |job|
          job_data = Services::JobDataService.get_job(job.name)
          latest_execution_data = nil
          if !job_data.nil?
            latest_execution_data = Services::JobDataService.get_execution(job.name, job_data.not_nil!.@latest_execution_id)
          end
          {info: job, latest_execution: latest_execution_data}
        end
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
        context.response.print Templates.run.job_execution(job_info, job_execution.not_nil!, job_execution_output)
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
        context.response.headers.add("X-Content-Type-Options", "nosniff")

        job_execution = Services::JobDataService.get_execution job_name, job_execution_id
        if job_execution.nil?
          next context
        end
        if job_execution.not_nil!.finished
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

      get "/api/job/:name/execution/:execution/exit_code" do |context, params|
        job_name = params["name"]
        job_execution_id = UInt32.new(params["execution"])
        context.response.headers.add("Content-Type", "text/plain")
        job_execution = Services::JobDataService.get_execution job_name, job_execution_id
        if !job_execution.nil? && job_execution.not_nil!.finished
          context.response.print job_execution.exit_code
        end
        context
      end

      get "/style.css" do |context, params|
        reply_asset context, "style.css", "text/css"
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
