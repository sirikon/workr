module Workr::Web::Templates
  extend self

  VERSION = {{ `shards version`.stringify }}

  {% if flag?(:release) %}
  CACHE_BUSTER = Time.utc.to_unix
  {% end %}

  class TemplateExecutionContext
    property io : IO = IO::Memory.new

    {% if flag?(:release) %}
    property cache_buster : Int64 = CACHE_BUSTER
    {% else %}
    property cache_buster : Int64 = Time.utc.to_unix_ms
    {% end %}

    def time_ago(time : Time)
      ago_text = ""
      time_ago = Time.utc - time
      if time_ago.days > 0
          ago_text = "#{time_ago.days} days ago"
      elsif time_ago.hours > 0
          ago_text = "#{time_ago.hours} hours ago"
      elsif time_ago.minutes > 0
          ago_text = "#{time_ago.minutes} minutes ago"
      else
          ago_text = "#{time_ago.seconds} seconds ago"
      end
      return ago_text
    end

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
