module Workr::Configuration
  extend self

  class Config
    include JSON::Serializable

    def initialize(
      @admin_password_hash : String,
      @jwt_secret : String
    ); end
  end

  def read : Config
    Config.from_json(File.read(Path[Dir.current] / "workr.json"))
  end
end
