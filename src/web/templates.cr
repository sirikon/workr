module Workr::Web::Templates
  extend self

  def home(jobs)
    ECR.render("./src/web/templates/home.ecr")
  end

  def job(job_info, job_executions)
    ECR.render("./src/web/templates/job.ecr")
  end

end
