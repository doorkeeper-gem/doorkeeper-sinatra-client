require "sinatra/base"
require "./lib/html_renderer"

# Load custom environment variables
load 'env.rb' if File.exists?('env.rb')

class DoorkeeperClient < Sinatra::Base
  enable :sessions

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

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
  end

  def client(token_method = :post)
    OAuth2::Client.new(
      ENV['OAUTH2_CLIENT_ID'],
      ENV['OAUTH2_CLIENT_SECRET'],
      :site         => "http://doorkeeper-provider.herokuapp.com",
      :token_method => token_method,
    )
  end

  def access_token
    OAuth2::AccessToken.new(client, session[:access_token])
  end

  def redirect_uri
    ENV['OAUTH2_CLIENT_REDIRECT_URI']
  end

  get '/' do
    erb :home
  end

  get '/sign_in' do
    redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri)
  end

  get '/sign_out' do
    session[:access_token] = nil
    redirect '/'
  end

  get '/callback' do
    new_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
    session[:access_token] = new_token.token
    redirect '/'
  end

  get '/explore/:api' do
    raise "Please call a valid endpoint" unless params[:api]
    begin
      response = access_token.get("/api/v1/#{params[:api]}")
      @json = JSON.parse(response.body)
      erb :explore, :layout => !request.xhr?
    rescue Exception => @error
      erb :error, :layout => !request.xhr?
    end
  end
end
