require "jwt"
require "../../configuration/config"

module Workr::Web::Utils::Auth
  extend self

  IDENTITY_COOKIE_KEY = "workr_identity"

  record Identity,
    is_admin : Bool

  def get_identity(context : HTTP::Server::Context)
    token = get_identity_token(context)
    if token.nil?
      return Identity.new(is_admin: false)
    end
    identity = parse_identity_token(token.not_nil!)
    if identity.nil?
      return Identity.new(is_admin: false)
    end
    identity
  end

  def set_identity(context : HTTP::Server::Context, identity : Identity)
    token = encode_identity_token(identity)
    set_identity_token(context, token)
  end

  private def parse_identity_token(token)
    identity = nil
    begin
      payload, header = JWT.decode(token, get_jwt_secret, JWT::Algorithm::HS512)
      identity = Identity.new(is_admin: payload["is_admin"].as_bool)
    rescue
    end
    identity
  end

  private def encode_identity_token(identity)
    payload = { "is_admin" => identity.is_admin }
    JWT.encode(payload, get_jwt_secret, JWT::Algorithm::HS512)
  end

  private def get_identity_token(context)
    cookie = context.request.cookies[IDENTITY_COOKIE_KEY]?
    if cookie.nil?
      return nil
    end
    return cookie.not_nil!.value
  end

  private def set_identity_token(context, token)
    context.response.cookies << HTTP::Cookie.new(
      name: IDENTITY_COOKIE_KEY,
      value: token)
  end

  private def get_jwt_secret
    Configuration.read.@jwt_secret
  end
end
