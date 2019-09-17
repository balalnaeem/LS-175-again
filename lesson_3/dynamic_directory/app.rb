require 'sinatra'
require 'sinatra/reloader'

get "/" do
  @files_arr = Dir.children('public').sort
  @files_arr.reverse! if params[:sort] == 'desc'

  erb :index
end
