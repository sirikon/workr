module Workr::Web::Templates
  extend self

  macro render(template_name)
    ECR.render("#{__DIR__}/templates/" + {{ template_name + ".ecr" }})
  end

  def home(jobs)
    render "home"
  end

  def job(job_info, job_executions)
    render "job"
  end

end
