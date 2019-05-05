# frozen_string_literal: true

require 'sinatra/base'
require 'securerandom'
require 'singleton'
require 'dotenv/load'
require './lib/html_renderer'

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
end

class App
  include Singleton

  attr_accessor :public_client_id,
                :public_client_redirect_uri,
                :confidential_client_id,
                :confidential_client_secret,
                :confidential_client_redirect_uri,
                :provider_url
end

App.instance.tap do |app|
  app.public_client_id = ENV['PUBLIC_CLIENT_ID']
  app.public_client_redirect_uri = ENV['PUBLIC_CLIENT_REDIRECT_URI']
  app.confidential_client_id = ENV['CONFIDENTIAL_CLIENT_ID']
  app.confidential_client_secret = ENV['CONFIDENTIAL_CLIENT_SECRET']
  app.confidential_client_redirect_uri = ENV['CONFIDENTIAL_CLIENT_REDIRECT_URI']
  app.provider_url = ENV['PROVIDER_URL']
end

class DoorkeeperClient < Sinatra::Base
  require 'rollbar/middleware/sinatra'
  use Rollbar::Middleware::Sinatra

  enable :sessions

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def pretty_json(json)
      JSON.pretty_generate(json)
    end

    def signed_in?
      !session[:access_token].nil?
    end

    def state_matches?(prev_state, new_state)
      return false if blank?(prev_state)
      return false if blank?(new_state)

      prev_state == new_state
    end

    def blank?(string)
      return true if string.nil?

      /\A[[:space:]]*\z/.match?(string.to_s)
    end

    def markdown(text)
      options  = { autolink: true, space_after_headers: true, fenced_code_blocks: true }
      markdown = Redcarpet::Markdown.new(HTMLRenderer, options)
      markdown.render(text)
    end

    def markdown_readme
      markdown(File.read(File.join(File.dirname(__FILE__), 'README.md')))
    end

    def site_host
      URI.parse(app.provider_url).host
    end
  end

  def app
    App.instance
  end

  def client
    public_send("#{session[:client]}_client")
  end

  def public_client
    OAuth2::Client.new(app.public_client_id, nil, site: app.provider_url)
  end

  def confidential_client
    OAuth2::Client.new(app.confidential_client_id, app.confidential_client_secret, site: app.provider_url)
  end

  def access_token
    OAuth2::AccessToken.new(client, session[:access_token], refresh_token: session[:refresh_token])
  end

  def generate_state!
    session[:state] = SecureRandom.hex
  end

  def generate_code_verifier!
    session[:code_verifier] = SecureRandom.uuid
  end

  def state
    session[:state]
  end

  def code_verifier
    session[:code_verifier]
  end

  def code_challenge_method
    'S256'
  end

  def code_challenge
    Base64.urlsafe_encode64(Digest::SHA256.digest(session[:code_verifier])).split('=').first
  end

  def authorize_url_for_client(type)
    session[:client] = type

    client.auth_code.authorize_url(
      redirect_uri: app.confidential_client_redirect_uri,
      scope: 'read',
      state: generate_state!,
      code_challenge_method: code_challenge_method,
      code_challenge: code_challenge
    )
  end

  get '/' do
    erb :home
  end

  get '/sign_in' do
    generate_code_verifier!
    redirect authorize_url_for_client(:confidential)
  end

  get '/public_sign_in' do
    generate_code_verifier!
    redirect authorize_url_for_client(:public)
  end

  get '/sign_out' do
    session[:access_token] = nil
    session[:refresh_token] = nil
    redirect '/'
  end

  get '/callback' do
    if params[:error]
      erb :callback_error, layout: !request.xhr?
    else
      unless state_matches?(state, params[:state])
        redirect '/'
        return
      end

      new_token =
        client
        .auth_code
        .get_token(
          params[:code],
          redirect_uri: app.confidential_client_redirect_uri,
          code_verifier: code_verifier
        )

      session[:access_token]  = new_token.token
      session[:refresh_token] = new_token.refresh_token
      redirect '/'
    end
  end

  get '/refresh' do
    new_token = access_token.refresh!
    session[:access_token]  = new_token.token
    session[:refresh_token] = new_token.refresh_token
    redirect '/'
  rescue OAuth2::Error => _e
    erb :error, layout: !request.xhr?
  rescue StandardError => _e
    erb :error, layout: !request.xhr?
  end

  get '/explore/:api' do
    raise 'Please call a valid endpoint' unless params[:api]

    begin
      response = access_token.get("/api/v1/#{params[:api]}")
      @json = JSON.parse(response.body)
      erb :explore, layout: !request.xhr?
    rescue OAuth2::Error => _e
      erb :error, layout: !request.xhr?
    end
  end
end
