require "sinatra/base"
require "./lib/html_renderer"

# Load custom environment variables
load 'env.rb' if File.exists?('env.rb')

class DoorkeeperClient < Sinatra::Base
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

    def markdown(text)
      options  = { :autolink => true, :space_after_headers => true, :fenced_code_blocks => true }
      markdown = Redcarpet::Markdown.new(HTMLRenderer, options)
      markdown.render(text)
    end

    def markdown_readme
      markdown(File.read(File.join(File.dirname(__FILE__), "README.md")))
    end

    def site_host
      URI.parse(ENV['SITE']).host
    end
  end

  def client(token_method = :post)
    OAuth2::Client.new(
      ENV['OAUTH2_CLIENT_ID'],
      ENV['OAUTH2_CLIENT_SECRET'],
      :site         => ENV['SITE'] || "http://doorkeeper-provider.herokuapp.com",
      :token_method => token_method,
    )
  end

  def access_token
    OAuth2::AccessToken.new(client, session[:access_token], :refresh_token => session[:refresh_token])
  end

  def redirect_uri
    ENV['OAUTH2_CLIENT_REDIRECT_URI']
  end

  get '/' do
    erb :home
  end

  get '/sign_in' do
    scope = params[:scope] || "public"
    redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => scope)
  end

  get '/sign_out' do
    session[:access_token] = nil
    redirect '/'
  end

  get '/callback' do
    if params[:error]
      erb :callback_error, :layout => !request.xhr?
    else
      new_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
      session[:access_token]  = new_token.token
      session[:refresh_token] = new_token.refresh_token
      redirect '/'
    end
  end

  get '/refresh' do
    begin
      new_token = access_token.refresh!
      session[:access_token]  = new_token.token
      session[:refresh_token] = new_token.refresh_token
      redirect '/'
    rescue OAuth2::Error => @error
      erb :error, :layout => !request.xhr?
    rescue StandardError => _error
      redirect '/'
    end
end

  get '/explore/:api' do
    raise "Please call a valid endpoint" unless params[:api]
    begin
      response = access_token.get("/api/v1/#{params[:api]}")
      @json = JSON.parse(response.body)
      erb :explore, :layout => !request.xhr?
    rescue OAuth2::Error => @error
      erb :error, :layout => !request.xhr?
    end
  end
end
