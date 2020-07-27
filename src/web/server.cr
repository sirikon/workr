require "router"
require "ecr"
require "../services/job_info_service"
require "../services/job_data_service"
require "./templates"

module Workr::Web::Server
  extend self

  class WebServer
    include Router

    def draw_routes
      get "/" do |context, params|
        jobs = Services::JobInfoService.get_all_jobs
        context.response.print Templates.home(jobs)
        context
      end
      get "/job/:name" do |context, params|
        job_info = Services::JobInfoService.get_job params["name"]
        job_executions = Services::JobDataService.get_all_executions(job_info.name)
        context.response.print Templates.job(job_info, job_executions)
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
