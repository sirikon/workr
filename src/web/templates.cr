module Workr::Web::Templates
  extend self

  class TemplateExecutionContext
    property io : IO = IO::Memory.new

    macro define_templates(*template_paths)
      {% for template_path, index in template_paths %}
        ECR.embed("#{__DIR__}/templates/" + {{ (template_path.id + ".ecr").stringify }}, @io)
      {% end %}
    end

    define_templates(
      "layouts/base",
      "home",
      "job",
      "job_execution"
    )
  end

  def run
    TemplateExecutionContext.new
  end
end
