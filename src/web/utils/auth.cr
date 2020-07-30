require "jwt"

module Workr::Web::Utils::Auth
  extend self

  IDENTITY_COOKIE_KEY = "workr_identity"
  JWT_SECRET = "secret"

  record Identity,
    is_admin : Bool

  def get_identity(context : HTTP::Server::Context)
    token = get_identity_token(context)
    if token.nil?
      return Identity.new(is_admin: false)
    end
    parse_identity_token(token.not_nil!)
  end

  private def parse_identity_token(token)
    payload, header = JWT.decode(token, JWT_SECRET, JWT::Algorithm::HS512)
    Identity.new(is_admin: payload["is_admin"].as_bool)
  end

  private def encode_identity_token(identity)
    payload = { "is_admin" => identity.is_admin }
    JWT.encode(payload, JWT_SECRET, JWT::Algorithm::HS512)
  end

  private def get_identity_token(context)
    cookie = context.request.cookies[IDENTITY_COOKIE_KEY]?
    if cookie.nil?
      return nil
    end
    return cookie.not_nil!.value
  end
end
