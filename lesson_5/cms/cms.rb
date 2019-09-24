require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

root = File.expand_path("..", __FILE__)

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)

  if File.extname(path) == ".md"
    erb render_markdown(content)
  else
    headers["Content-Type"] = "text/plain"
    content
  end
end

# Create file path depending on which environment the code is running in
def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end

  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# Check if the user is signed in
def user_signed_in?
  session.key?(:username)
end

# if user not signed in, redirect to the homepade and set a message
def required_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

# View list of all files
get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end.sort

  erb :index
end

# Create a new file
get "/new" do
  required_signed_in_user
  erb :new
end

post "/new" do
  if params[:name] == ""
    session[:message] = "A name is required from you."
    erb :new
  else
    file_path = File.join(data_path, params[:name])
    File.write(file_path, "")
    session[:message] = "#{params[:name]} was created."
    redirect "/"
  end
end

# View a single file
get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Edit a file
get "/:filename/edit" do
  required_signed_in_user

  file_path = File.join(data_path, params[:filename])
  @file_content = File.read(file_path)
  erb :edit
end

# Update a file
post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  File.open(file_path, "w") { |file| file.puts params[:new_content] }

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

# Delete a file
post "/delete/:filename" do
  required_signed_in_user

  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.delete(file_path)
  session[:message] = "#{filename} has been deleted."
  redirect "/"
end

# Sign in form
get "/users/signin" do
  erb :signin
end

# Submit the sign in form
post "/users/signin" do
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    session[:message] = "Welcome!"
    session[:username] = username
    redirect "/"
  else
    session[:message] = "Invalid Credentials!"
    status 422
    erb :signin
  end
end

# Sign out
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."

  redirect "/"
end






























