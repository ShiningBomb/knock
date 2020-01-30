require_dependency 'knock/application_controller'

module Knock
  class AuthTokenController < ApplicationController
    before_action :authenticate, only: [:create]

    def create
      unless entity.respond_to? :generate_refresh_token!
        render json: auth_token, status: :created
      end

      refresh_token = entity.generate_refresh_token!
      render json: { access_token: auth_token.token, refresh_token: refresh_token }, status: :created
    end

    def refresh
      unless entity_class.respond_to? :from_refresh_token
        raise Knock.not_found_exception_class
      end

      refresh_entity = entity_class.from_refresh_token params['refresh_token']
      raise Knock.not_found_exception_class unless refresh_entity

      @entity = refresh_entity
      render json: { access_token: auth_token.token }, status: :created
    end

    private
    def authenticate
      unless entity.present? && entity.authenticate(auth_params[:password])
        raise Knock.not_found_exception_class
      end
    end

    def auth_token
      if entity.respond_to? :to_token_payload
        AuthToken.new payload: entity.to_token_payload
      else
        AuthToken.new payload: { sub: entity.id }
      end
    end

    def entity
      @entity ||=
        if entity_class.respond_to? :from_token_request
          entity_class.from_token_request request
        else
          entity_class.find_by email: auth_params[:email]
        end
    end

    def entity_class
      entity_name.constantize
    end

    def entity_name
      self.class.name.scan(/\w+/).last.split('TokenController').first
    end

    def auth_params
      params.require(:auth).permit :email, :password
    end
  end
end
