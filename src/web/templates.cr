module Workr::Web::Templates
  extend self

  class TemplateExecutionContext
    property io : IO = IO::Memory.new

    macro define_templates(*template_defs)
      {% for template_def, index in template_defs %}
        def {{template_def.first.id}}({% for fragment, index in template_def %}{% if index > 1 %},{% end %}{% if index != 0 %}{{ fragment.id }}{% end %}{% end %})
          ECR.embed("#{__DIR__}/templates/" + {{ (template_def.first.id.gsub(/\_\_/, "/") + ".ecr").stringify }}, @io)
        end
      {% end %}
    end

    define_templates(
      {"layouts__base", "&"},
      {"home", "jobs"},
      {"job", "job_info", "job_executions"},
      {"job_execution", "job_info", "job_execution", "job_execution_output"})
  end

  def run
    TemplateExecutionContext.new
  end
end
