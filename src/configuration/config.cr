require "json"
require "crypto/bcrypt/password"

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
    Config.from_json(File.read(config_path))
  end

  def write(config : Config)
    File.write(config_path, config.to_json)
  end

  def wizard
    jwt_secret = ask_for("JWT secret")
    admin_password = ask_for("Admin password")
    admin_password_hash = Crypto::Bcrypt::Password.create(admin_password, cost: 10)
    write Config.new(admin_password_hash.to_s, jwt_secret)
  end

  private def ask_for(description)
    print "#{description}: "
    value = gets || ""
    if value === ""
      puts "Value can't be empty"
      exit 1
    end
    value
  end

  private def config_path
    Path[Dir.current] / "workr.json"
  end
end
