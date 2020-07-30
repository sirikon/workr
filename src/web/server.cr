require "router"
require "ecr"
require "crypto/bcrypt/password"
require "../configuration/config"
require "./utils/ansi_filter"
require "./utils/auth"
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
      {{ctx}}.response.headers.add("Cache-Control", "max-age=604800")
      {{ctx}}.response.content_type = {{content_type}}
      {% if flag?(:embed_web_assets) %}
        {{ctx}}.response.print {{ read_file("#{__DIR__}/assets/" + path) }}
      {% else %}
        {{ctx}}.response.print File.read("#{__DIR__}/assets/" + {{path}})
      {% end %}
      {{ctx}}
    end

    def draw_routes

      get "/login" do |context, params|
        context.response.print get_templates(context).login()
        context
      end
      get "/logout" do |context, params|
        identity = Utils::Auth::Identity.new(is_admin: false)
        Utils::Auth.set_identity(context, identity)
        context.response.status = HTTP::Status::SEE_OTHER
        context.response.headers.add("Location", "/")
        context
      end
      post "/login" do |context, params|
        username = nil
        password = nil
        HTTP::FormData.parse(context.request) do |part|
          case part.name
          when "username"
            username = part.body.gets_to_end
          when "password"
            password = part.body.gets_to_end
          end
        end

        context.response.status = HTTP::Status::SEE_OTHER
        if username.nil? || password.nil?
          context.response.headers.add("Location", "/login")
          next context
        end

        config = Configuration.read
        context.response.status = HTTP::Status::SEE_OTHER
        bcrypt_pass = Crypto::Bcrypt::Password.new(config.@admin_password_hash)

        if username == "admin" && bcrypt_pass.verify(password)
          identity = Utils::Auth::Identity.new(is_admin: true)
          Utils::Auth.set_identity(context, identity)
          context.response.headers.add("Location", "/")
        else
          context.response.headers.add("Location", "/login")
        end
        context
      end

      get "/" do |context, params|
        jobs = Services::JobInfoService.get_all_jobs.map do |job|
          job_data = Services::JobDataService.get_job(job.name)
          latest_execution_data = nil
          if !job_data.nil?
            latest_execution_data = Services::JobDataService.get_execution(job.name, job_data.not_nil!.@latest_execution_id)
          end
          {info: job, latest_execution: latest_execution_data}
        end
        context.response.print get_templates(context).home(jobs)
        context
      end
      get "/job/:name" do |context, params|
        job_info = Services::JobInfoService.get_job params["name"]
        job_executions = Services::JobDataService.get_all_executions(job_info.name)
        context.response.print get_templates(context).job(job_info, job_executions)
        context
      end
      get "/job/:name/execution/:execution" do |context, params|
        job_name = params["name"]
        job_execution_id = UInt32.new(params["execution"])
        job_info = Services::JobInfoService.get_job params["name"]
        job_execution = Services::JobDataService.get_execution job_name, job_execution_id
        job_execution_output = Services::JobDataService.get_execution_output job_name, job_execution_id
        ansi_filter = Utils::AnsiFilter.new
        context.response.print get_templates(context).job_execution(job_info, job_execution.not_nil!, ansi_filter.filter(job_execution_output))
        context
      end
      post "/job/:name/run" do |context, params|
        identity = get_identity(context)
        if !identity.is_admin
          context.response.status = HTTP::Status::UNAUTHORIZED
          next context
        end
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

        ansi_filter = Utils::AnsiFilter.new
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
              context.response.write(ansi_filter.filter(bytes))
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

      get "/style.:buster.css" do |context, params|
        reply_asset context, "style.css", "text/css"
      end
      get "/job_execution.:buster.js" do |context, params|
        reply_asset context, "job_execution.js", "text/javascript"
      end
    end

    private def get_templates(context)
      Templates.run(
        get_identity(context))
    end

    private def get_identity(context)
      Utils::Auth.get_identity(context)
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
