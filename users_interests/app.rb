require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

before do
  @users = YAML.load_file("users.yml")
end

helpers do
  def count_interests
    @users.reduce(0) do |sum, (name, details)|
      sum + details[:interests].size
    end
  end
end

get "/" do
  @title = "Users"
  erb :index
end

get "/:user" do
  @title = params[:user]
  @email = params[:user]

  erb :user
end